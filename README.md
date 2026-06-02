# Rokid CXR-L uni-app iOS native plugin

This project builds a uni-app iOS native plugin wrapper for Rokid CXR-L SDK.

## What it produces

The GitHub Actions workflow builds and packages:

```text
dist/Rokid-CXRL.zip
```

The zip contains:

```text
Rokid-CXRL/
  package.json
  ios/
    RokidCXRLUniPlugin.framework
    RGCxrClient.framework
    RGCoreKit.framework
    CocoaLumberjack.framework
```

Put the unzipped `Rokid-CXRL` directory into your uni-app project's
`nativeplugins` directory, then make a custom iOS base.

## JavaScript usage

```js
const cxrl = uni.requireNativePlugin('Rokid-CXRL')

cxrl.initialize({
  mode: 'customApp',
  appDisplayName: 'YourApp',
  pageName: 'com.rokid.cxrswithcxrl'
}, (ret) => {
  console.log('init', ret)
})

cxrl.watchEvents({}, (event) => {
  console.log('cxrl event', event)
})

cxrl.authenticate({
  scopes: ['device_control', 'audio_stream'],
  appName: 'YourApp'
}, (ret) => {
  console.log('auth', ret)
})
```

## Important build note

The provided `RGCxrClient.framework` was built with a newer Swift toolchain.
If GitHub Actions cannot import the Swift module, use a runner image with a
matching or newer Xcode, or ask the SDK vendor for an xcframework built with
the Xcode version available on GitHub Actions.

## Local files used as references

- `D:\projects\dcloud SDK\SDK\HBuilder-uniPluginDemo`
- `D:\projects\ios_cxr_l_sample\ios_cxr_l_sample`

