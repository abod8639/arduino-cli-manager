# Contributing to Arduino CLI Manager

Thank you for your interest in contributing to Arduino CLI Manager! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior** vs **actual behavior**
- **Environment details**:
  - OS version (Linux distro, macOS version, etc.)
  - Bash version: `bash --version`
  - arduino-cli version: `arduino-cli version`
  - fzf version (if applicable): `fzf --version`
- **Error messages** or screenshots if applicable

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Use case**: Why would this enhancement be useful?
- **Proposed solution**: How should it work?
- **Alternatives considered**: What other solutions did you consider?

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes**:
   - Follow the coding style guidelines below
   - Add comments for complex logic
   - Test your changes thoroughly
3. **Update documentation**:
   - Update README.md if you add/change features
   - Update README_AR.md for Arabic documentation
   - Add comments to explain your code
4. **Commit your changes**:
   - Use clear, descriptive commit messages
   - Reference issues in commits when applicable
5. **Submit a pull request**

## Coding Style Guidelines

### Shell Script Style

- **Indentation**: Use 4 spaces (no tabs)
- **Line length**: Keep lines under 100 characters when possible
- **Function names**: Use lowercase with underscores (e.g., `install_library`)
- **Variable names**: 
  - Local variables: lowercase with underscores
  - Global/config variables: UPPERCASE with underscores
- **Comments**: 
  - Use `#` for single-line comments
  - Add function headers explaining purpose and parameters
- **Error handling**:
  - Always check return codes
  - Provide meaningful error messages
  - Use the `handle_error` function for consistency

### Example Function Structure

```bash
# --- Section Header ---
function example_function() {
    # Brief description of what this function does
    local param1="$1"
    local param2="${2:-default_value}"
    
    # Validate inputs
    if [[ -z "$param1" ]]; then
        echo -e "${C_RED}Error: param1 is required${C_RESET}"
        return 1
    fi
    
    # Main logic
    echo -e "${C_GREEN}Processing...${C_RESET}"
    
    # Error handling
    if ! some_command; then
        handle_error "command_name" "error details"
        return 1
    fi
    
    # Success
    echo -e "${C_GREEN}Success!${C_RESET}"
    log_operation "OPERATION_NAME" "SUCCESS" "$param1"
    return 0
}
```

### Color Usage

Use the predefined color variables:
- `C_RED`: Errors
- `C_GREEN`: Success messages
- `C_YELLOW`: Warnings
- `C_BLUE`: Information
- `C_CYAN`: Highlights
- `C_PURPLE`: Special items
- `C_RESET`: Reset to default

### Testing Your Changes

Before submitting a pull request:

1. **Test basic functionality**:
   - Project selection
   - Board selection
   - Port selection
   - Compilation
   - Upload
   - Serial monitor

2. **Test new features**:
   - Verify your new feature works as expected
   - Test edge cases
   - Test error handling

3. **Test on different systems** (if possible):
   - Linux (Ubuntu, Arch, etc.)
   - macOS
   - WSL (Windows Subsystem for Linux)

4. **Test with and without optional dependencies**:
   - With fzf installed
   - Without fzf (fallback menus)
   - With/without jq

### Documentation

- Update README.md for any user-facing changes
- Update README_AR.md to keep Arabic documentation in sync
- Add inline comments for complex logic
- Update help text if adding new menu options

## Project Structure

```
arduino-cli-manager/
├── arduino-cli-manager.sh  # Main script
├── README.md               # English documentation
├── README_AR.md            # Arabic documentation
├── LICENSE                 # MIT License
├── CONTRIBUTING.md         # This file
├── Makefile               # Build/install automation
├── PKGBUILD               # Arch Linux package
└── build.sh               # Build script
```

## Feature Requests

We welcome feature requests! When suggesting a feature:

1. **Check existing issues** to avoid duplicates
2. **Describe the problem** you're trying to solve
3. **Propose a solution** with implementation details
4. **Consider alternatives** and explain why your solution is best

## Questions?

If you have questions about contributing:

- Open an issue with the "question" label
- Check existing issues and pull requests
- Review the README.md for usage information

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Arduino CLI Manager! 🎉
