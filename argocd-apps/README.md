# ArgoCD Applications

This directory contains ArgoCD Application manifests for GitOps deployment.

## Structure

- Each `.yaml` file defines an ArgoCD Application
- Applications are automatically synced by the app-of-apps pattern
- Add new applications here to deploy them to the cluster

## Example

See `example-app.yaml` for a template.
