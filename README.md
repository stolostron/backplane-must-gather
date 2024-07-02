# Must Gather Script for Multicluster Engine (MCE)

**NOTE:** The `stolostron/backplane-must-gather` repository is a mirrored subset of the Advanced Cluster Management (ACM) `stolostron/must-gather`. Changes must be submitted in a Pull Request to https://github.com/stolostron/must-gather, after which the changes will be mirrored here.

## Usage

See the `stolostron/must-gather` [README.md](https://github.com/stolostron/must-gather/tree/main?tab=readme-ov-file) for usage, replacing the `stolostron/must-gather` image with `stolostron/backplane-must-gather`, for instance:

```sh
oc adm must-gather --image=quay.io/stolostron/backplane-must-gather:SNAPSHOTNAME
```
