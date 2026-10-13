fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios test

```sh
[bundle exec] fastlane ios test
```

Run unit and integration tests

### ios sync_signing

```sh
[bundle exec] fastlane ios sync_signing
```

Sync certificates and provisioning profiles via Match

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload beta build to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and submit release to App Store Connect

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload screenshots to App Store Connect

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Capture real screenshots from simulator, then upload to App Store Connect

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
