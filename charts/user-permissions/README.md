# moondog-navigator

A utility chart for managing ClusterRoles, Roles, and corresponding bindings for Users and Groups

## TL;DR

* Write a single set of `roleDefinitions` to describe the permissions that you might want to grant your Users and Groups.
* Configure `bindings.cluster` to generate cluster-level ClusterRoles and ClusterRoleBindings.
* Configure `bindings.namespaces` to generate namespaced Roles and RoleBindings.

Example:

```yaml
roleDefinitions:
  read-write-all:
    - apiGroups:
        - '*'
      resources:
        - '*'
      verbs:
        - '*'
    - nonResourceURLs:
        - '*'
      verbs:
        - '*'
  read-all:
    - apiGroups:
        - '*'
      resources:
        - '*'
      verbs:
        - get
        - watch
        - list
    - nonResourceURLs:
        - '*'
      verbs:
        - get
        - watch
        - list

bindings:
  cluster:
    groups:
      administrators:
        - read-write-all
      engineers:
        - read-all
    users:
      root:
        - read-write-all
  namespaces:
    demo:
      groups:
        guests:
          - read-all
```

## Role definitions in depth

The `roleDefinitions` configuration section defines ClusterRoles and/or Roles that _may_ be created by the chart. Each key is the name of the potential ClusterRole/Role, and the value is its [set of `rules`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole).

Example:

```yaml
roleDefinitions:
  read-write-all-resources:
    - apiGroups:
        - '*'
      resources:
        - '*'
      verbs:
        - '*'
  read-all-resources:
    - apiGroups:
        - '*'
      resources:
        - '*'
      verbs:
        - get
        - watch
        - list
```

The chart will create a ClusterRole for a given definition _only if you ask to use it_ in the `bindings.cluster` section of the chart configuration.

The chart will create a Role for a given definition on namespace `"foo"` _only if you ask to use it_ in the `bindings.cluster.foo` section of the chart configuration.

## Bindings in depth

The `bindings.cluster` section deals with ClusterRoles and ClusterRoleBindings, and the `bindings.namespaces` section deals with namespaced Roles and RoleBindings.

Example:

```yaml
bindings:
  cluster:
    groups:
      administrators:
        - read-write-all
      engineers:
        - read-all
    users:
      alice:
        - read-write-all
  namespaces:
    demo:
      groups:
        demo-guests:
          - read-all
      users:
        bob:
          - read-write-all
```

In the above example:

* The Group `"administrators"` will be granted the `"read-write-all"` ClusterRole.
* The Group `"engineers"` will be granted the `"read-all"` ClusterRole.
* The User `"alice"` will be granted the `"read-write-all"` ClusterRole.
* The Group `"demo-guests"` will be granted the `"read-all"` Role on the Namespace `"demo"`.
* The User `"bob"` will be granted the `"read-write-all"` Role on the Namespace `"demo"`.
