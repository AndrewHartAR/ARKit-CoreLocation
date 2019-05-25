# Changelog

- next
    - [PR #184 - adds "ignoreAltitude" to LocationNode](https://github.com/ProjectDent/ARKit-CoreLocation/pull/184)
    - [PR #182 - child node scaling](https://github.com/ProjectDent/ARKit-CoreLocation/pull/182)
    - [PR #181 - Cleans up warnings](https://github.com/ProjectDent/ARKit-CoreLocation/pull/181)
    - [PR #177 - Fixes the workspace schemes](https://github.com/ProjectDent/ARKit-CoreLocation/pull/177)
    - [PR #176 - Fixes issue #164](https://github.com/ProjectDent/ARKit-CoreLocation/pull/176)
        - Fixes an issue where dismissing the ARCL Scene View can make other UIs unusable
        - Creating LocationNodes from a UIView now just creates an image from that view and uses the image.
    - [PR #171 - Support Carthage and open SceneLocationView for extension](https://github.com/ProjectDent/ARKit-CoreLocation/pull/171)
- 1.1.0
    - [PR #159 - Directions (Routes) and AR Polylines](https://github.com/ProjectDent/ARKit-CoreLocation/pull/159)
        - Adds the ability to take an array of `MKRoute` objects and render it as a route in AR (similar to the demo gif on the README)
        - Updates the demo app to allow you to demonstrate this capability
