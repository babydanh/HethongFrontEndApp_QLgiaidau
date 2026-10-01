# Social location provider

The Social picker uses the Sporto API's authenticated `/social-locations/search`, `/social-locations/resolve`, and `/social-locations/reverse` routes through the shared `DioClient`. The backend owns Photon configuration; the app does not need `SOCIAL_LOCATION_API_URL`.

The app still parses Google Maps links and expands `maps.app.goo.gl` redirects locally with a separate unauthenticated HTTP client. Only the resulting address text or coordinates go to Sporto. The existing Regions search remains an independent source for province and ward results without pins.

When the geocoder fails and Regions has no matches, the picker shows a retryable service error rather than a false “no results” state. A successful pinned resolve or reverse lookup can proceed to map preview and confirmation. Deployment must bring up private Photon and the backend routes before releasing this app build.
