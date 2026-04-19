# 🌌 Space Shooter (Sovereign / Overclock)

![Godot Engine](https://img.shields.io/badge/GODOT-%23FFFFFF.svg?style=for-the-badge&logo=godot-engine)
![Script](https://img.shields.io/badge/GDScript-%23FFFFFF.svg?style=for-the-badge&logo=godot-engine)
![Status](https://img.shields.io/badge/Status-Active-success.svg?style=for-the-badge)

A high-fidelity top-down space survival combat game built in **Godot 4**. The project focuses on mathematical procedural generation, advanced enemy swarm mechanics, and performance-first rendering.

## ✨ Features
* **Sovereign Escalation Quota:** An industry-standard progressive enemy spawn system (inspired by Vampire Survivors), utilizing a hard on-screen population cap `(5 + WaveNumber^1.6)` to prevent early swarms while scaling into massive chaos.
* **Procedural Deep Space Rendering:** Instead of static image backgrounds, the game employs GLSL-grade Domain-Warped Fractional Brownian Motion inside custom Godot Shaders to generate infinite, beautiful, distinct galaxies every run.
* **True Multi-Layer Parallax:** Deep cosmos depth mapping separates foreground stars from background nebulae, moving correctly with the player's 2D transform to simulate astronomical scale.
* **Dynamic Fleet AI:** Tactical enemy repulsion physics using inverse-distance forces prevents clustering and enables clear tactical maneuvering.

## 🛠️ Architecture
Built purely in GDScript (`.gd`) with standard Godot 4.x patterns. All background logic runs entirely on the GPU via custom CanvasItem Shaders (`.gdshader`).

## 👨‍💻 Author Info
This project is actively developed and maintained by:
* **Developer:** Sakibur Rahman
* **Email:** [sakiburrahmannnn@gmail.com](mailto:sakiburrahmannnn@gmail.com)
* **GitHub:** [@SakiburRahmann](https://github.com/SakiburRahmann)
