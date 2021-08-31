# Pre-requisite tools

*You may skip the installation of all the following tools and run `try-sat` from a [pre-built container image](https://github.com/l2fprod/ibmcloud-ci), maintained by Fred Lavigne, that includes most of them already.*

*To do this, run the Docker image, clone this repo, and run `make install`:*
```bash
docker run -it --volume $PWD:/root/mnt/home --workdir /root/mnt/home l2fprod/ibmcloud-ci
git clone https://github.ibm.com/garage-satellite-guild/try-sat.git
cd try-sat
make install
```

Otherwise, the list of pre-requisites you need follows. This list is long-ish, but most of these are tools that either you likely already have, or will be important in this ecosystem.

### Mandatory

*   [IBM Cloud CLI](https://cloud.ibm.com/docs/cli). This should also install `kubectl` (or make sure you have it another way).

*   [oc, the OpenShift CLI](https://docs.openshift.com/container-platform/4.6/cli_reference/openshift_cli/getting-started-cli.html#installing-openshift-cli). You can also install this on MacOS, assuming you have Homebrew, with `brew install openshift-cli`.

*   Terraform. If you have `tfswitch` - see below - `try-sat` should automatically obtain the correct version for you. Alternatively, on MacOS, assuming you have Homebrew, just run `brew install terraform` to install the most recent version (the minimum version currently required is 0.14.3, you can find out what you have with `terraform -version`)

*   [jq](https://stedolan.github.io/jq/manual/). On MacOS, assuming you have Homebrew, just run `brew install jq`.

*   *WireGuard VPN Client*. For MacOS, install from [the Mac OS App Store](https://apps.apple.com/us/app/wireguard/id1451685025?mt=12).

*   Run `make install` to ensure that various IBM Cloud CLI plugins are installed.

### Optional (but useful)

*   [direnv](https://direnv.net/). This makes it easier to use `.envrc`. On MacOS, assuming you have Homebrew, just run `brew install direnv` (you then need to set up `direnv` as per its man page).

*   [tfswitch](https://tfswitch.warrensbox.com/Install/). This tool makes it easier to make sure you are using the right Terraform version. If it's installed, `try-sat` will use it automatically. On MacOS, just run `brew install warrensbox/tap/tfswitch`.
