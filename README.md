# Design of a Microprocessor

## Overview

This project involved designing a device to simulate a processor inside another processor. The device can be programmed in real-time and execute the written program by emulating the fetch, decode, and execute cycles of a real processor in software.

## Functionality

- The programming process allows entering arbitrary data at desired memory addresses as opcodes or operands using the keyboard.

- The programming uses a finite state machine with states like entering an address, confirming it, entering a data value etc. Special function keys are provided for utilities.

- The execution emulates the typical processor cycles to fetch, decode and execute instructions based on the programmed code.

- Internal registers are defined for program counter, stack pointer, instruction register etc.

## Challenges

- Converting keyboard input to opcodes and operands

- Correctly storing data in memory  

- Implementing the programming finite state machine

- Simulating the instruction execution cycle fully in software

- Limitations in interacting with external world for I/O

## Conclusion

The project succeeded in developing a microprocessor that can be programmed in real-time and execute any assembly code like an actual processor (with some limitations). The programming and execution cycles were emulated in software using a finite state machine model and minimal processor registers.

## References

See the original Persian report PDF for more details.
