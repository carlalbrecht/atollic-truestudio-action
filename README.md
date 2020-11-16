# Atollic TrueSTUDIO GitHub Action
This GitHub Action allows STM32 firmware binaries to be built from TrueSTUDIO C/C++ projects.

Note: By using TrueSTUDIO, you agree to its [EULA](http://gotland.atollic.com/resources/licenses/ts_sla0047.pdf).

## Usage
### Inputs
 * `project`: The path to one or more directories containing a TrueSTUDIO `.project` file, relative to the repository root. Bash pattern matching operators (including globstar) can be used to match multiple locations. By default, this is set to the repository root.
 * `build`: [Project name]/[Build configuration] to build. Both the project name and build configuration can be regular expressions. If this input is set to `all`, all configurations for all projects are built. By default, this is set to `all`.

### Example workflow - upload a firmware release asset

When a new GitHub release is created, build all firmware projects under the `firmware` directory of the repository, then upload `example-project`'s firmware binary as a release asset:

```yaml
name: Upload Firmware Release Asset

on:
  release:
    types:
      - created

jobs:
  build:
    name: Upload Firmware Release Asset
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Build with TrueSTUDIO
        uses: carlalbrecht/atollic-truestudio-action@v1
        with:
          project: firmware/*
          build: .*/Debug
      - name: Upload firmware release asset
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ github.event.release.upload_url }}
          asset_path: ./firmware/example-project/Debug
          asset_name: example-project.hex
          asset_content_type: binary/octet-stream
```

Build outputs are located in the same directories as when the project is built through the TrueSTUDIO desktop interface - in a child directory inside the project directory, whose name matches the build configuration used.
