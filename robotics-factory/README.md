# Robotics Project — mBot2 Robot@Factory Lite

Autonomous mobile robot developed on the **mBot2 platform** for the **Robot@Factory Lite** robotics competition task.

| | |
|---|---|
| **Status** | Partial — first mission sequence achieved; full competition task not completed |
| **Context** | Academic — Robotics, University of Beira Interior, 2024 |
| **Team** | Alexandre Saraiva, Daniela Fernando, Diogo Soares |
| **My contribution** | Actuators: electromagnet circuit and 3D-printed mount (SolidWorks); infrared sensor interface (not completed). Programming was done by a teammate. |
| **Evidence** | [Report (PT, PDF)](report.pdf) · [video](https://www.youtube.com/watch?v=6UiQEKMYRqw) · photo below |

---

## Project Demonstration

Video demonstration of the robot: https://www.youtube.com/watch?v=6UiQEKMYRqw

---

## Project Goal

The objective was to design and program an autonomous robot capable of navigating an industrial-style factory map and transporting objects.

The robot needed to:

- Navigate autonomously through the factory layout
- Detect paths and intersections
- Pick up a box using an electromagnet
- Deliver the object to the correct destination

---

## Robot Platform

The project used the **mBot2 robotics platform** developed by Makeblock, with the **CyberPi** controller (Wi-Fi, sensor integration, motor control with encoders, Python and block programming).

![Prototype](robotADD.png)

---

## Hardware Components

- mBot2 robot platform
- CyberPi controller
- Ultrasonic distance sensor
- Quad RGB line follower sensor
- DC motors with encoders
- Custom electromagnet actuator
- Custom 3D printed mount (SolidWorks)

The electromagnet was designed to tow and transport the factory box.

---

## Software & Programming

The robot was programmed using:

- mBlock software
- Scratch-based control logic

An attempt was made to implement the **A\* pathfinding algorithm**, but due to time constraints and complexity the final implementation used rule-based navigation.

---

## Control Strategy

The factory map was divided into grid cells to represent the environment.

Each cell represented:

- 0 → Free path
- 1 → Obstacle

This approach was intended to let the robot determine its position and plan movement through the factory map (A\* approach, later abandoned).

---

## Results

The robot completed the first mission sequence:

1. Leave starting area
2. Pick up box using electromagnet
3. Navigate to delivery point
4. Drop the box
5. Return to pickup area

However, the robot often missed intersections while correcting its position on the line, which prevented completion of the full competition path. As stated in the report, the robot did not reach the point of being ready to take part in the competition.
