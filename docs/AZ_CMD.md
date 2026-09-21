# AZ_CMD

This file contains handy az-cli commands used in this project.

## Azure CLI Commands

### CAE Commands

- Responds "Succeeded" if the below CAE is provisioned:

    ```bash
    az containerapp env show \
      -g "rg-rgomesapp-dev" \
      -n "cae-rgomes-dev" \
      --query properties.provisioningState
    ```

- List CAEs on a given RG:

    ```bash
    az containerapp env list \
      -g "rg-rgomesapp-dev"
    ```

### ACR commands

- List all the repositories in a registry:

    ```bash
    az acr repository list \
      --name "crrgomesdev01" \
      --output json
    ```

- Image tag/version:

    ```bash
    az acr repository show-tags \
      --name "crrgomesdev01" \
      --repository "dev/nettools" \
      --output table
    # 0.0.9
    ```

- Delete a specific image from the repo:

    ```bash
    az acr repository delete \
      --name "crrgomesdev01" \
      --image "dev/nettools":0.0.9
    ```

- Image and registry name:

    ```bash
    az acr repository show \
      --name "crrgomesdev01" \
      --repository "dev/nettools" \
      --output json
    # "crrgomesdev01".azurecr.io
    # "dev/nettools"
    ```

- Image Reference:

    ```text
    # <registry>/<image-name>:<tag>
    "crrgomesdev01".azurecr.io/"dev/nettools":0.0.9
    ```

## Display ACA Settings

- Display the container app currently configured ingress target port:

    ```bash
    az containerapp ingress show \
      --name "ca-nettools-dev" \
      --resource-group "rg-rgomesapp-dev" \
      --query targetPort
    ```

- Cointainer Appp full settings (image, env vars, resources, scale, ingress,
  registries...)

    ```bash
    # ACA name rg-rgomesmathmcp-dev
    az containerapp show \
      -g "rg-rgomesapp-dev"\
      -n "ca-nettools-dev" \
      --output json
    ```

- Just the running image + env vars

    ```bash
    az containerapp show \
      -g "rg-rgomesapp-dev" \
      -n "ca-nettools-dev" \
      --query "properties.template.containers[].{image:image, env:env}"
    ```

- Ingress config (external/internal, target port, transport)

    ```bash
    az containerapp ingress show \
      -g "rg-rgomesapp-dev" \
      -n "ca-nettools-dev"
    ```

- Registries configured for pulling images, and which identity they use

    ```bash
    az containerapp registry list \
      -g "rg-rgomesapp-dev" \
      -n "ca-nettools-dev"
    ```

- Managed identity assigned to the app (needed for AcrPull)

    ```bash
    az containerapp identity show \
      -g "rg-rgomesapp-dev" \
      -n "ca-nettools-dev"
    ``` 

- Secrets defined on the app (names only, values are not returned)

    ```bash
    az containerapp secret list \
      -g "rg-rgomesapp-dev" \
      -n "ca-nettools-dev"
    ```

- Revisions (active/inactive, traffic split, image per revision)

    ```bash
    az containerapp revision list \
      -g "rg-rgomesapp-dev" \
      -n "ca-nettools-dev"  \
      --output json
    ```

- Provisioning/health state only

    ```bash
    az containerapp show \
      -g "rg-rgomesapp-dev" \
      -n "ca-nettools-dev" \
      --query "{state:properties.provisioningState, fqdn:properties.configuration.ingress.fqdn}"
    ```

- Show the scale setting provisioned:

    ```bash
    az containerapp revision list \
      -n "ca-nettools-dev" \
      -g "rg-rgomesapp-dev" \
      --query "[].{name:name, active:properties.active, replicas:properties.replicas, provisioningState:properties.provisioningState}" \
      -o table
    ```

- List live container app replicas (empty response means no replica running):

    ```bash
    az containerapp replica list \
      --name "ca-nettools-dev" \
      --resource-group "rg-rgomesapp-dev" \
      --output table
    ```

### Start / Stop Container APP

1. Start by ensuring you have one replica

    ```bash
    az containerapp update \
      -n "ca-nettools-dev" \
      -g "rg-rgomesapp-dev" \
      --min-replicas 1
    ```

2. Stop by ensuring you have 0 replicas

    ```bash
    az containerapp update \
      -n "ca-nettools-dev" \
      -g "rg-rgomesapp-dev" \
      --min-replicas 0
    ```

3. Deactivate the revision, which immediately tears down all its replicas.

    ```bash
    az containerapp revision deactivate \
      --name "ca-nettools-dev" \
      --resource-group "rg-rgomesapp-dev" \
      --revision "ca-nettools-dev--0000004"
    ```

### Connect to Container App Console + Debug Console

1. Shell into the real container app shell:

    ```bash
    az containerapp exec \
      --name "ca-nettools-dev" \
      --resource-group "rg-rgomesapp-dev" \
      --command /bin/bash
    ```

2. Shell into a **debug** container app shell. This is a separate, ephemeral
   debug container that Azure attaches alongside the real replica.

    ```bash
    az extension add --name containerapp --upgrade
    az containerapp debug \
      --name "ca-nettools-dev" \
      --resource-group "rg-rgomesapp-dev"
    ```

### Other Miscellaneous Container App Commands

1. Find the HTTP endpoint URL:

    ```bash
    az containerapp show \
      --name "ca-nettools-dev" \
      --resource-group "rg-rgomesapp-dev" \
      --query properties.configuration.ingress.fqdn \
      --output tsv
        # http://"ca-nettools-dev".internal.wittygrass-3e0d023f.centralus.azurecontainerapps.io:8080/health
    ```

2. Live log stream

    ```bash
    az containerapp logs show \
      -g "rg-rgomesapp-dev" \
      -n "ca-nettools-dev" --follow
    ```
