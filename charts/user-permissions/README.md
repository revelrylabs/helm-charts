# moondog-navigator

A utility chart for managing ClusterRoles, Roles, and corresponding bindings for Users and Groups

## TL;DR

* Write a single set of `roleDefinitions` to describe the permissions that you might want to grant your Users and Groups.
* Configure `bindings` to generate corresponding `(Cluster)Role`s and `(Cluster)RoleBinding`s.

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

# NOTE: `namespace: '*'` denotes cluster-level access.

bindings:
  - group: administrators
    bindTo:
      # Members of the "admninistrators" group have cluster-wide read and write permissions.
      - namespace: '*'
        roles:
          - read-write-all
  - group: readers
    bindTo:
      # Members of the "readers" group have cluster-wide read permissions.
      - namespace: '*'
        roles:
          - read-all
  - group: demo-guests
    bindTo:
      # Members of the "demo-guests" group have read permissions in namespace "demo".
      - namespace: demo
        roles:
          - read-all
  - user: alice
    bindTo:
      # User "alice" has cluster-wide read permissions.
      - namespace: '*'
        roles:
          - read-all
      # User "alice" has read and write permissions in namespace "demo".
      - namespace: demo
        roles:
          - read-write-all
```

## Role definitions in depth

The `roleDefinitions` configuration section defines `ClusterRole`s and/or `Role`s that _may_ be created by the chart. Each key is the name of the potential `ClusterRole`/`Role`, and the value is its [set of `rules`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole).

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

Corresponding `ClusterRole`s or `Role`s will be created from these definitions (or not) based upon the `bindings` you define. See the next section for more details.

## Bindings in depth

`ClusterRole`s and `ClusterRoleBinding`s belong to the cluster itself and grant permissions on every namespace. In the chart's configuration, we denote cluster-level access with `namespace: '*'`.

`Role`s and `RoleBinding`s belong to a `Namespace` and grant permissions only within that `Namespace`. In the chart's configuration, we denote access to a `Namespace` named "foo" with `namespace: "foo"`.

For each combination of `namespace` and role name found in the `bindings` configuration, the chart will create:

  * One `ClusterRole` or `Role` whose rules come from the same-named `roleDefinitions` key.
  * One `ClusterRoleBinding` or `RoleBinding` of the same name, which will bind the `Role`/`ClusterRole` to every `Group` or `User` that has a `bindTo` for that `namespace` role name.

Consider the following `values.yaml`:

```yaml
# Obviously, to actually set permissions,
# You would give these definitions some rules.
roleDefinitions:
  read-all: []
  read-all-except-secrets: []
  write-all: []
  unused-definition: []

bindings:
  - group: alpha
    bindTo:
      - namespace: '*'
        roles:
          - read-all-except-secrets # Grant cluster-level "read-all-except-secrets" to Group "alpha"
      - namespace: foo
        roles:
          - read-all # Grant "read-all" to Group "alpha" in Namespace "foo"
          - write-all # Grant "write-all" to Group "alpha" in Namespace "foo"
  - group: bravo
    bindTo:
      - namespace: foo
        roles:
          - read-all-except-secrets # Grant read-all-except-secrets to Group "bravo" in Namespace "foo"
  - user: bob
    bindTo:
      - namespace: '*'
        roles:
          - read-all # Grant cluster-level "real-all" to User "bob"
      - namespace: foo
        roles:
          - read-all # Grant "read-all" to User "bob" in Namespace "foo"
          - write-all # Grant "write-all" to User "bob" in Namespace "foo"

```

This is how the chart creates Kubernetes resources:

* No `ClusterRole` or `Role`s are created for "unused-definition" because no subjects use it.
* At the cluster level:
  * Creates `ClusterRole` "read-all"
  * Creates `ClusterRoleBinding` "read-all"
    * Which binds `ClusterRole` "read-all" to subjects:
      * `User` "bob"
  * Creates `ClusterRole` "read-all-except-secrets"
  * Creates `ClusterRoleBinding` "read-all-except-secrets"
    * Which binds `ClusterRole` "read-all-except-secrets" to subjects:
      * `Group` "alpha"
* In namespace "foo":
  * Creates `Role` "read-all"
  * Creates `RoleBinding` "read-all"
    * Which binds `Role` "read-all" to subjects:
      * `Group` alpha
      * `User` "bob"
  * Creates `Role` "write-all"
  * Creates `RoleBinding` "write-all"
    * Which binds `Role` "write-all" to subjects:
      * `Group` "alpha"
      * `User` "bob"
  * Creates `Role` "read-all-except-secrets"
  * Creates `RoleBinding` "read-all-except-secrets"
    * Which binds `Role` "read-all-except-secrets" to subjects:
      * `Group` "bravo"
