# Attack Surface
## Theory
Attack Surface explains how many application's components are exported, if the application is debuggable.

## Practical
Drozer allows to audit the Attack surface.
```bash
dz> run app.package.attacksurface com.application
Attack Surface:
  2 activities exported
  3 broadcast receivers exported
  0 content providers exported
  1 services exported
```

## References
{% embed url="https://subscription.packtpub.com/book/networking-and-servers/9781785883149/4/ch04lvl1sec33/identifying-the-attack-surface" %}
