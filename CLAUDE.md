# CLAUDE.md

## Sandbox Environment

This Claude Code is running in a Docker-based sandbox environment behind Merck's corporate firewall with configurable internet access control. Your workspace (`/workspace`) is mounted from the host project directory.

### Available Languages & Runtimes

| Language | Version | Command |
|----------|---------|---------|
| **Node.js** | 24.x | `node`, `npm` |
| **Python** | 3.12.12 | `python3`, `pip3` |
| **R** | 4.5.2 | `R`, `Rscript` |

### Python Environment

#### Package Manager
- **uv** (0.9.21) - Fast package manager; use for virtual environments
- **pip3** - Standard package manager

#### Recommended: Use Virtual Environments
```bash
uv venv && source .venv/bin/activate
uv pip install package-name
```

#### Pre-installed Python Packages

**Data Science & Math:**
- `numpy` (1.26.4), `scipy` (1.12.0), `pandas` (2.2.1)
- `scikit-learn` (1.4.1), `scikit-image` (0.22.0)
- `sympy` (1.12.1), `networkx` (3.3)

**Visualization:**
- `matplotlib` (3.8.3), `seaborn` (0.13.2)

**Computer Vision & Images:**
- `opencv-python` (4.9.0), `Pillow`
- `pytesseract` (0.3.10), `pycocotools` (2.0.8)

**Document Processing:**
- PDF: `pypdf`, `pdf2image`, `PyPDF2` (3.0.1), `pdfminer.six`
- Office: `python-pptx`, `python-docx` (1.1.0), `openpyxl` (3.1.2), `xlrd`, `xlwt`
- Web/XML: `beautifulsoup4` (4.12.3), `lxml` (5.2.2), `defusedxml`

**Audio/Video:**
- `ffmpeg-python`

**Utilities:**
- `requests` (2.32.3), `tqdm` (4.66.4), `PyYAML` (6.0.1)
- `bcrypt` (4.3.0), `markdown` (3.7)

### R Environment

#### Pre-installed R Packages

**Core & Tidyverse:**
- `tidyverse`, `dplyr`, `ggplot2`, `devtools`, `roxygen2`

**Statistics & Bayesian Analysis:**
- `rstan`, `brms`, `lme4`, `binom`, `MASS`, `Matrix`, `mgcv`

**Machine Learning:**
- `xgboost`, `randomForest`, `randomForestSRC`, `caret`
- `e1071`, `rpart`, `nnet`

**Survival Analysis:**
- `survival`, `survMisc`, `survminer`

**Design of Experiments & Testing:**
- `rsm`, `DoE.base`, `FrF2`, `multcomp`, `nparcomp`, `pwr`

**Reporting:**
- `r2rtf`, `rtf`

**User library path:** `/workspace/.rlibs` (persisted in project folder)

### System Tools

#### CLI Tools
- **AWS CLI v2** - Cloud operations
- **GitHub CLI (`gh`)** - GitHub operations (use `gh auth login` to authenticate)
- **Git** with **delta** (0.18.2) - Version control with syntax highlighting
- **jq** - JSON processor
- **curl**, **wget** - HTTP clients

#### Media & Document Processing
- **ffmpeg** - Audio/video processing
- **ImageMagick** - Image manipulation
- **Tesseract OCR** - Optical character recognition
- **Pandoc** - Document conversion
- **LibreOffice** - Office document processing (headless)
- **poppler-utils** - PDF utilities (`pdftotext`, `pdftoppm`, etc.)

#### Build Tools
- **make**, **cmake**, **g++**, **gfortran**

### File Structure

| Path | Purpose |
|------|---------|
| `/workspace` | Your project directory (mounted from host) |
| `/workspace/.venv` | Python virtual environment (create with `uv venv`) |
| `/home/node/.claude` | Claude Code global settings |
| `/workspace/.rlibs` | User R packages (persisted) |

### Network Access

The sandbox runs behind a corporate proxy with firewall restrictions and configurable internet access control.

#### HTTP/HTTPS (via proxy)
Web traffic passes through the corporate proxy. You can access:
- Package registries (npm, PyPI, CRAN)
- GitHub, Hugging Face
- AWS Bedrock, Anthropic APIs
- Scientific databases (ClinicalTrials.gov, PubMed/NCBI, FDA)
The access list can be expanded upon request.

#### Non-HTTP Protocols (Blocked by default in the sandbox)
SSH, database connections, FTP, and direct IP connections are blocked unless explicitly allowed.

### Common Tasks

#### Create a Python virtual environment
```bash
uv venv && source .venv/bin/activate
```

#### Install Python packages
```bash
# In virtual environment (recommended)
uv pip install package-name

# System-wide (use sparingly)
pip3 install package-name
```

#### Authenticate with GitHub
```bash
gh auth login
```

#### Run scripts
```bash
python3 script.py
Rscript script.R
node script.js
```

### Notes

- Shell: `zsh` (default) with fzf integration
- Editor: `nano` (default), `vim` available
- SSL verification is disabled for git and npm due to corporate proxy
- Your project files persist on the host; container state persists in Docker volumes
