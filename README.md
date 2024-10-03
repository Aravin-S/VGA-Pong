# Project Title: FPGA-based Real-Time Signal Generator and Pong Game Implementation

## Project Summary:
This project focuses on implementing a Pong game using the Xilinx Spartan-3E FPGA board. The game is displayed on a VGA monitor and controlled through on-board switches. The primary goal was to gain practical experience with real-time signal generation on an FPGA, particularly in video output subsystems and VGA standards, and to develop proficiency in VHDL coding for real-time applications.

The Simple Video-Game Processor (SVGP) designed for the project handles both static and dynamic elements, including paddles, a moving ball, and game boundaries. The game runs at a 640x480 resolution using a 25 MHz DAC clock for the VGA display, with paddle controls mapped to specific switches.

The project was successful in meeting the objectives of implementing a working Pong game, handling all real-time dynamics such as ball movement and collision detection with walls or paddles, as well as resetting the ball when a goal is scored.

## Tools and Technologies Used:
- **FPGA:** Xilinx Spartan-3E
- **VHDL:** For digital circuit design and implementation
- **VGA Standard:** Video output via a VGA monitor
- **Xilinx ISE CAD System:** Used for coding and synthesizing VHDL designs
- **Digital-to-Analog Converter (DAC):** Used to generate analog VGA signals
