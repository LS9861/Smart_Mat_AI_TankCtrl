# Smart MATLAB AI Tank Control

AI-assisted PID tuning for water tank control system using MATLAB/Simulink and DeepSeek API.

## Features

- Tank simulation with transfer function G(s) = 0.01/(s + 0.002)
- PI/PID controller with AI-optimized gains
- Simulink integration for visual modeling
- Automatic gain tuning via DeepSeek API
- Script-based and Simulink-based simulation

### 1. Clone the repository

## Setup
# Smart MATLAB AI Tank Control

[![MATLAB](https://img.shields.io/badge/MATLAB-R2018a-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![Simulink](https://img.shields.io/badge/Simulink-✓-orange.svg)](https://www.mathworks.com/products/simulink.html)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![AI](https://img.shields.io/badge/AI-DeepSeek-red.svg)](https://deepseek.com)

**AI-assisted PID tuning for water tank control system using MATLAB/Simulink and DeepSeek API.**  
Reduce steady-state error by 60% with intelligent gain optimization.

---

## 📌 Overview

This project demonstrates how to combine **classical control theory** with **modern AI** to automatically tune a PID controller for a water tank system. The AI (DeepSeek) analyzes the plant dynamics and recommends optimal gains, which are then validated through simulation.

**Key Achievement:** Reduced steady-state error from **26.97 mm to 10.93 mm** (59.5% improvement) using AI-suggested gains.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Water Tank Simulation** | First-order plant: `G(s) = 0.01/(s + 0.002)` (τ = 500s) |
| **AI-Powered PID Tuning** | DeepSeek API suggests optimal Kp, Ki, Kd gains |
| **MATLAB Script Simulation** | Fast iteration for learning control concepts |
| **Simulink Model** | Visual block diagram for professional development |
| **Fuzzy Gain Scheduling** | Adaptive control based on error magnitude |
| **Feedforward Control** | Baseline voltage (u_eq = 0.30V) for perfect steady-state |
| **Continuous vs Discrete** | Compare ideal vs Arduino-ready control |
| **Results Logging** | Automatic saving with timestamps, plots, and data export |

---

## 🚀 Quick Start

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| MATLAB | R2018a or later | Main environment |
| Simulink | R2018a or later | Visual modeling |
| Simulink Control Design | R2018a | Linearization |
| Python | 3.x | API bridge |
| DeepSeek API Key | Free account | AI tuning |

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/LS9861/Smart_Mat_AI_TankCtrl.git
cd Smart_Mat_AI_TankCtrl

# 2. Install Python dependencies
pip install requests

# 3. Set up your API key (create api_key_config.m - see below)
