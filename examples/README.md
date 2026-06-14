# EEEval Examples

This directory contains several examples showcasing the capabilities of the `eeeval` library.

## Examples

### 1. Gaussian Distribution (`gaussian.cr`)
Demonstrates how to evaluate the Probability Density Function (PDF) of a Normal Distribution. It shows both single-value evaluation and efficient vector-based evaluation using Tensors.

**To run:**
```bash
crystal examples/gaussian.cr
```

### 2. Mandelbrot Set (`mandelbrot.cr`)
A visual demonstration of complex plane iteration. It uses EEEval to compute the iterative step of the Mandelbrot set and renders an ASCII visualization in the terminal.

**To run:**
```bash
crystal examples/mandelbrot.cr
```

### 3. Monte Carlo Pi Estimation (`monte_carlo_pi.cr`)
Uses random sampling and expression evaluation to estimate the value of Pi. This demonstrates how to use pre-compiled ASTs for repetitive calculations in a loop.

**To run:**
```bash
crystal examples/monte_carlo_pi.cr
```

### 4. CLI Usage Examples
You can also use the `eeeval` CLI (if built) to perform quick range evaluations:

**Gaussian-like distribution on CLI:**
```bash
./bin/eeval -v x -s -3 -e 3 -d 0.5 -D s=1 -D m=0 "1/(s * sqrt(2*pi)) * exp(-0.5 * ((x-m)/s)^2)"
```
