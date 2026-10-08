# TL;DR

This folder holds kubernetes deployment and service resources for the gen3 web portal.
The portal also imports configuration for the commons' manifest (see below).
Configure and launch the portal with `gen3 kube-setup-portal`.

# Portal customization

Several flags and files in a deployment [manifest](https://github.com/uc-cdis/cdis-manifest) are available to customize the behavior and appearance of the gen3 web [portal](https://github.com/uc-cdis/data-portal).

First, the `portal_app` property in the `global` object of `manifest.json`
determines which "profile" the portal runs with.  The portal's profile
includes customizations necessary for the common's dictionary, so the `bhc` portal_app
customizes the portal to work with the brain commons' dictionary.

Second, the optional `tier_access_level` property in the `global` object of `manifest.json` determines the access level of a common. Valid options for `tier_access_level` are `libre`, `regular` and `private`. Common will be treated as `private` by default.
For `regular` level data commons, there's another configuration environment variable `tier_access_limit`, which is the minimum visible count for aggregation results. By default set to 1000. 

Third, for the GEARBOx (gearbox-frontend) portal, these optional properties in the `global` object of `manifest.json` are passed to the portal as environment variables and read at container start (a pod restart is enough, no image rebuild):
- `react_app_enhanced_ui`: set to the string `"true"` to enable the enhanced matching UI (`REACT_APP_ENHANCED_UI`). Any other value, or leaving it unset, keeps the original form.
- `deploy_production_data_url` and `refresh_production_data_url`: endpoints the admin "deploy staged trials to production" action POSTs to, in that order (`DEPLOY_PRODUCTION_DATA_URL`, `REFRESH_PRODUCTION_DATA_URL`). Use paths reachable from the portal's origin. If either is empty the action fails.

See the [gearbox-frontend README](https://github.com/chicagopcdc/gearbox-frontend#environment-variables) for details.

The portal includes support for several customization profiles in its code base in various files under the [data/config](https://github.com/uc-cdis/data-portal/tree/master/data/config)
and [custom/](https://github.com/uc-cdis/data-portal/tree/master/custom) folders.
An environment may also define its own `gitops` profile by installing files
under a manifest's `portal/` folder (for example - [reuben.planx-pla.net/portal](https://github.com/uc-cdis/gitops-dev/tree/master/reuben.planx-pla.net))
that override the default `gitops` profile defined in cloud-automation
[here](https://github.com/uc-cdis/cloud-automation/tree/master/kube/services/portal/defaults):
```
$ ls -1F kube/services/portal/defaults/
gitops-createdby.png
gitops.css
gitops-favicon.ico
gitops.json
gitops-logo.png
```./kube/services/portal/README.md
