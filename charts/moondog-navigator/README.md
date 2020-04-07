# moondog-navigator

Moondog Navigator helps you browse and understand what's happening in your Kubernetes clusters.

## Prerequisites

Moondog Navigator uses OpenID Connect (OIDC) to authenticate each user against your Kubernetes cluster. This provides out-of-the-box security that obeys individual user permissions.

### If you already have an OpenID Connect provider/strategy in place...

Create a client configuration for Moondog Navigator, and gather all of the information you will need to be able to configure the `clusters` section of our chart:

```yaml
clusters:
  - name: mycluster # alphanumeric, all lowercase, no spaces
    api:
      url: https://<YOUR K8 API SERVER'S HOST>:6443
      oidcClientId: <THE VALUE OF YOUR KUBERNETES CLUSTER API'S --oidc-client-id FLAG>
    caCertUrl: <URL OF YOUR CA CERTIFICATE FILE>
    oidc:
      authUrl: <YOUR OIDC PROVIDER'S AUTH URL>
      tokenUrl: https://<YOUR OIDC PROVIDER'S TOKEN URL>
      clientId: <MOONDOG NAVIGATOR OIDC CLIENT ID>
      clientSecret: <MOONDOG NAVIGATOR OIDC CLIENT SECRET>
```

### Getting Started with OpenID Connect (OIDC)

We recommend the OIDC provider [dex](https://github.com/dexidp/dex) for operators who are just getting started.

Install [Dex](https://hub.helm.sh/charts/stable/dex) via its Helm chart. Here is an example configuration for the `staticClients` section. Supply a custom secret, and point the `redirectURI` at the domain where you intend to host Moondog Navigator. Also be sure you add/update the trustedPeers section as shown below:

```yaml
staticClients:
  - id: dex
    name: dex
    secret: MyDexSecret
    redirectURIs:
      - https://dex.example.com/callback
    trustedPeers:
      - moondog
  - id: moondog
    name: moondog-navigator
    secret: MyMoondogNavigatorClientSecret
    redirectURIs:
      - https://moondog-navigator.example.com/kubernetes/auth/callback
```

Configure the Kubernetes API server flags to use Dex, using this guide: https://github.com/dexidp/dex/blob/master/Documentation/kubernetes.md#configuring-the-openid-connect-plugin

## Adding the `revelrylabs` Helm repo

```sh
$ helm repo add revelrylabs https://revelrylabs.github.io/helm-charts
```

## Installing the chart

```sh
$ helm install revelrylabs/moondog-navigator -f your-config.yaml --namespace your-namespace
```

## Configuration

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| replicaCount | The number of web server pod replicas for the deployment | 1 |
| clusters | A list of clusters that Moondog Navigator can browse and interact with. | [] |
| image.repository | The Docker repo to pull the image from. | revelrylabs/moondog-navigator |
| image.tag | The Docker image tag to pull. | v1beta2 |
| image.pullPolicy | The `imagePullPolicy` for the Deployment. | IfNotPresent |
| imagePullSecrets | Secrets to be used if you are going to pull the image from a private Docker repo. | [] |
| nameOverride | If set, overrides the name `"moondog-navigator"` with this. | "" |
| fullnameOverride | If set, overrides the full name, including the release name prefix, with this. | "" |
| serviceAccount.create | Specifies whether a service account should be created. | true |
| serviceAccount.name | The name of the service account to use. If not set and create is true, a name is generated using the fullname template. |  |
| appDomain | The canonical domain of the web server. If you add an Ingress, make sure this matches | localhost |
| ingress.enabled | Whether or not to create an Ingress. | false |
| ingress.annotations | Annotations for the created Ingress. | {} |
| ingress.hosts | Hosts spec for the created Ingress. | [] |
| ingress.tls | TLS spec for the created Ingress. | [] |
| service.type |  | ClusterIP |
| service.port |  | 80 |
| containerPort | The port on which the web server in the container is listening. We do not recommend changing this. | 5000 |
| podSecurityContext |  | {} |
| securityContext |  | {} |
| resources |  | {} |
| nodeSelector |  | {} |
| tolerations |  | [] |
| affinity |  | {} |

## Example Configuration

Notes:

* A cluster's `api.url` is the URL of its Kubernetes API service.
* The `api.oidcClientId` should match the value of the Kubernetes API service's `--oidc-client-id` flag.
* A cluster's OIDC `clientId` and `clientSecret` should match the static client you configured for Moondog Navigator in Dex.
* The ingress' host should match the host of the `redirectURI` you configured in Dex.

```yaml
appDomain: moondog.example.com

clusters:
  - name: production
    api:
      url: https://k8api.example.com:6443
      oidcClientId: dex
    caCertUrl: https://certs.example.com/etc/kubernetes/pki/ca.crt
    oidc:
      authUrl: https://dex.example.com/auth
      tokenUrl: https://dex.example.com/token
      clientId: moondog
      clientSecret: MyMoondogClientSecret

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-production
  hosts:
    - host: moondog.example.com
      paths: ["/"]
  tls:
    - secretName: moondog-navigator-cert
      hosts:
        - moondog.example.com
```
