# RC-Neutral-Axis-Finder
"MATLAB tool to compute neutral axis depth (c) for reinforced concrete rectangular sections using force equilibrium and bisection method."
# RC Neutral Axis Finder (MATLAB)

This project is a MATLAB-based reinforced concrete section analysis tool that calculates the **neutral axis depth (c)** for a **rectangular reinforced concrete cross-section** using **force equilibrium**.

The program allows the user to manually input reinforcement bar coordinates and then iteratively determines the neutral axis location using the **bisection method**.

---

## 📌 Features

- Rectangular reinforced concrete section analysis
- Manual reinforcement placement by coordinate input (x, y)
- Reinforcement visualization (dilated bar area)
- Strain distribution calculation based on neutral axis depth
- Steel yielding / non-yielding classification
- Steel force computation (elastic or yielded)
- Concrete compression block contribution (0.85 fcd)
- Neutral axis depth (c) calculation using **bisection method**
- Graphical output:
  - Strain distribution diagram
  - Steel force distribution diagram

---

## ⚙️ Input Parameters

The following properties are defined in the code:

### Material Properties
- Steel yield strain: `epsilon_sy`
- Steel design yield strength: `fyd`
- Concrete design compressive strength: `fcd`
- Steel modulus of elasticity: `E`

### Section Geometry
- Width: `kisa_kenar`
- Height: `uzun_kenar`
- Concrete cover: `paspayi`

### Reinforcement
- Bar diameter: `donati_capi`
- Total number of bars: `toplam_yerlestirilecek_donati`

---

## 🧠 Method

The program solves the equilibrium equation:

\[
\sum F_s + F_c = 0
\]

Where:
- \(F_s\) is the total reinforcement force (tension or compression)
- \(F_c\) is the concrete compression block force

Concrete compression block is calculated as:

\[
F_c = 0.85 \cdot f_{cd} \cdot k_1 \cdot c \cdot b
\]

Neutral axis depth \(c\) is found iteratively using the **bisection method** until force equilibrium is satisfied.

---

## ▶️ How to Run

1. Open MATLAB
2. Run the script file:
   ```matlab
   RC_NeutralAxisFinder.m
