#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ThingSpeak.h>

// =====================================================
// Configuração Wi-Fi
// =====================================================
constexpr char WIFI_SSID[]     = "M23 de Alexandre";
constexpr char WIFI_PASSWORD[] = "************";

// =====================================================
// Configuração ThingSpeak
// =====================================================
constexpr unsigned long THINGSPEAK_CHANNEL_ID = 2914672;
constexpr char THINGSPEAK_API_KEY[] = "KX31KE59JBRZURX8";

// =====================================================
// Definição de pinos
// =====================================================
constexpr uint8_t PIN_ANALOGICO = A0;
constexpr uint8_t PIN_BOMBA     = 4;   // D2
constexpr uint8_t PIN_MUX       = 14;  // D5
constexpr uint8_t PIN_SENSORES  = 5;   // D1

// =====================================================
// Limiares do sistema
// =====================================================
constexpr int NIVEL_MINIMO_BRUTO   = 100;
constexpr int HUMIDADE_MINIMA      = 60;
constexpr int HUMIDADE_OBJETIVO    = 63;

// =====================================================
// Calibração dos sensores
// Ajusta estes valores conforme os teus testes reais
// =====================================================
constexpr int NIVEL_ADC_MIN = 0;
constexpr int NIVEL_ADC_MAX = 465;

constexpr int HUM_ADC_SECO  = 1024; // solo seco
constexpr int HUM_ADC_HUMIDO = 0;   // solo húmido

// =====================================================
// Temporizações
// =====================================================
constexpr unsigned long TEMPO_ESTABILIZACAO_MS = 100;
constexpr unsigned long TEMPO_REGA_LEITURA_MS  = 250;
constexpr unsigned long TIMEOUT_WIFI_MS        = 15000;
constexpr unsigned long TIMEOUT_REGA_MS        = 30000;
constexpr unsigned long TEMPO_DEEP_SLEEP_US    = 10000000; // 10 s

// =====================================================
// Objetos globais
// =====================================================
WiFiClient wifiClient;

// =====================================================
// Estrutura de dados
// =====================================================
struct Leituras {
  int nivelBruto;
  int nivelPct;
  int humidadeBruta;
  int humidadePct;
};

// =====================================================
// Funções utilitárias
// =====================================================
void ligarSensores() {
  digitalWrite(PIN_SENSORES, HIGH);
}

void desligarSensores() {
  digitalWrite(PIN_SENSORES, LOW);
}

void desligarBomba() {
  digitalWrite(PIN_BOMBA, LOW);
}

void ligarBomba() {
  digitalWrite(PIN_BOMBA, HIGH);
}

void desligarSistema() {
  desligarBomba();
  desligarSensores();
}

bool ligarWiFi() {
  if (WiFi.status() == WL_CONNECTED) {
    return true;
  }

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("A ligar ao Wi-Fi");
  const unsigned long inicio = millis();

  while (WiFi.status() != WL_CONNECTED && (millis() - inicio < TIMEOUT_WIFI_MS)) {
    delay(500);
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWi-Fi ligado com sucesso.");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    return true;
  }

  Serial.println("\nFalha na ligação Wi-Fi.");
  return false;
}

int mediaAnalogica(uint8_t muxState, uint8_t amostras = 5) {
  digitalWrite(PIN_MUX, muxState);
  delay(TEMPO_ESTABILIZACAO_MS);

  long soma = 0;
  for (uint8_t i = 0; i < amostras; ++i) {
    soma += analogRead(PIN_ANALOGICO);
    delay(5);
  }

  return soma / amostras;
}

int lerNivelAguaBruto() {
  return mediaAnalogica(LOW);
}

int lerHumidadeBruto() {
  return mediaAnalogica(HIGH);
}

int converterNivelPercentagem(int leitura) {
  int percentagem = map(leitura, NIVEL_ADC_MIN, NIVEL_ADC_MAX, 0, 100);
  return constrain(percentagem, 0, 100);
}

int converterHumidadePercentagem(int leitura) {
  int percentagem = map(leitura, HUM_ADC_SECO, HUM_ADC_HUMIDO, 0, 100);
  return constrain(percentagem, 0, 100);
}

Leituras lerSensores() {
  Leituras dados{};

  ligarSensores();

  dados.nivelBruto    = lerNivelAguaBruto();
  dados.nivelPct      = converterNivelPercentagem(dados.nivelBruto);
  dados.humidadeBruta = lerHumidadeBruto();
  dados.humidadePct   = converterHumidadePercentagem(dados.humidadeBruta);

  desligarSensores();
  return dados;
}

void mostrarLeituras(const Leituras& dados) {
  Serial.print("Nível bruto: ");
  Serial.print(dados.nivelBruto);
  Serial.print(" | Nível (%): ");
  Serial.print(dados.nivelPct);
  Serial.print(" | Humidade bruta: ");
  Serial.print(dados.humidadeBruta);
  Serial.print(" | Humidade (%): ");
  Serial.println(dados.humidadePct);
}

bool enviarParaThingSpeak(const Leituras& dados) {
  if (!ligarWiFi()) {
    Serial.println("Sem Wi-Fi. Dados não enviados.");
    return false;
  }

  ThingSpeak.setField(1, dados.humidadePct);
  ThingSpeak.setField(2, dados.nivelPct);

  const int codigo = ThingSpeak.writeFields(THINGSPEAK_CHANNEL_ID, THINGSPEAK_API_KEY);

  Serial.print("Código ThingSpeak: ");
  Serial.println(codigo);

  if (codigo == 200) {
    Serial.println("Dados enviados com sucesso.");
    return true;
  }

  Serial.println("Erro ao enviar dados.");
  return false;
}

Leituras regarAteHumidadeIdeal() {
  Serial.println("Solo seco e nível de água suficiente. A iniciar rega...");
  ligarBomba();

  const unsigned long inicioRega = millis();
  Leituras dados{};

  while (true) {
    ligarSensores();

    dados.nivelBruto = lerNivelAguaBruto();
    dados.nivelPct   = converterNivelPercentagem(dados.nivelBruto);

    if (dados.nivelBruto < NIVEL_MINIMO_BRUTO) {
      Serial.println("Nível de água insuficiente. A parar bomba.");
      desligarBomba();
      desligarSensores();
      break;
    }

    dados.humidadeBruta = lerHumidadeBruto();
    dados.humidadePct   = converterHumidadePercentagem(dados.humidadeBruta);

    desligarSensores();

    Serial.print("Humidade durante rega: ");
    Serial.print(dados.humidadePct);
    Serial.println("%");

    if (dados.humidadePct >= HUMIDADE_OBJETIVO) {
      Serial.println("Humidade ideal atingida. A parar bomba.");
      desligarBomba();
      break;
    }

    if (millis() - inicioRega > TIMEOUT_REGA_MS) {
      Serial.println("Timeout de rega atingido. A parar bomba por segurança.");
      desligarBomba();
      break;
    }

    delay(TEMPO_REGA_LEITURA_MS);
    yield();
  }

  return lerSensores();
}

// =====================================================
// Setup
// =====================================================
void setup() {
  Serial.begin(115200);

  pinMode(PIN_BOMBA, OUTPUT);
  pinMode(PIN_SENSORES, OUTPUT);
  pinMode(PIN_MUX, OUTPUT);
  pinMode(PIN_ANALOGICO, INPUT);

  desligarSistema();

  ThingSpeak.begin(wifiClient);
  ligarWiFi();

  Serial.println("Sistema iniciado.");
}

// =====================================================
// Loop principal
// =====================================================
void loop() {
  desligarSistema();

  Leituras dados = lerSensores();
  mostrarLeituras(dados);

  enviarParaThingSpeak(dados);

  if (dados.nivelBruto <= NIVEL_MINIMO_BRUTO) {
    Serial.println("Nível de água insuficiente. Rega não autorizada.");
  } else if (dados.humidadePct < HUMIDADE_MINIMA) {
    dados = regarAteHumidadeIdeal();
    mostrarLeituras(dados);
    enviarParaThingSpeak(dados);
  } else {
    Serial.println("Humidade suficiente. Não é necessário regar.");
  }

  desligarSistema();
  Serial.println("A entrar em Deep Sleep...\n");
  ESP.deepSleep(TEMPO_DEEP_SLEEP_US);
}
