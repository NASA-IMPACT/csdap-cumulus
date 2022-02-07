# Development

- [Upgrading Cumulus](#upgrading-cumulus)
  - [Determining the Upgrade Path](#determining-the-upgrade-path)
  - [Upgrading to the Next Version in the Upgrade Path](#upgrading-to-the-next-version-in-the-upgrade-path)

## Upgrading Cumulus

### Determining the Upgrade Path

When upgrading Cumulus from version _X_ to version _Y_, unless otherwise noted
in the Cumulus release notes, it is recommended that you do _not_ directly
upgrade to version _Y_, unless version _Y_ is the version that immediately
follows _X_. Rather, you should incrementally _upgrade through each version of
Cumulus_ that follows version _X_, in order, until version _Y_ is reached.

However, with a bit of time spent reviewing the Cumulus tags and release notes,
you may be able to quickly determine that one or more versions _can_ be skipped
in the upgrade process.

For example, let's assume this repository is using Cumulus version 9.7.0, and we
want to upgrade to version 10.0.1. We must first determine the versions released
between versions 9.7.0 and 10.0.1. The easiest way to do so is to visit the
[Cumulus tags] page, where we would find the following reverse chronological
sequence (as of 10.0.1 being the latest release):

- v10.0.1
- v10.0.0
- v9.7.1
- v10.0.0-beta.0
- v9.2.4
- v9.2.3
- v9.9.0
- v9.8.0
- v9.7.0

We can immediately eliminate any versions that are less than our current version
(9.7.0) because they are backports of bug fixes for earlier versions.  We can
also eliminate any beta versions. This leaves us with the following list (after
also eliminating our current version, 9.7.0):

- v10.0.1
- v10.0.0
- v9.7.1
- ~~v10.0.0-beta.0~~
- ~~v9.2.4~~
- ~~v9.2.3~~
- v9.9.0
- v9.8.0
- ~~v9.7.0~~

Since 9.7.1 is a patch release backporting a bug fix, we can eliminate that one
as well. Finally, 10.0.1 is also a patch release, so we can "skip" 10.0.0, but we
**must** take care to follow the instructions for 10.0.0.  This leaves us with
this _potential_ upgrade path:

- v10.0.1 (**IMPORTANT:** Follow release notes for v10.0.0!)
- v9.9.0
- v9.8.0

At this point, we must look at the [release notes][Cumulus releases] for versions
9.8.0 and 9.9.0 to determine if there are any specific migration notes that
require us to make specific configuration changes to our infrastructure.  As it
turns out, neither of these versions include any migration steps for us to take.
They consist solely of some code changes that don't require us to make any
changes, other than bumping the Cumulus version.

Therefore, we can upgrade from 9.7.0 directly to 10.0.1, but we must follow the
migration steps given for the 10.0.0 release.

Regardless of the current version and the target version, the same logic can be
followed to determine the upgrade path.  Once the upgrade path is determined
(9.7.0 -> 10.0.1 [with the caveat of following migration steps for 10.0.0], in
the example above), the following section outlines how to go from one version
in the upgrade path to the next version in the path.

For each version change in the upgrade path, you must repeat the steps in the
following section. In our example above, there is only one version change (from
9.7.0 to 10.0.1, while following the migration steps for 10.0.0), so the example
requires following the steps in the next section only once.

However, if in our example, the path were 9.7.0 -> 9.9.0 -> 10.0.1, we would
have to follow the steps in the following section _twice_: once for 9.7.0 ->
9.9.0, and again for 9.9.0 -> 10.0.1.

### Upgrading to the Next Version in the Upgrade Path

To upgrade to a particular version of Cumulus, do the following:

1. Check out this repository's `main` branch and pull the latest changes.
1. Create a new branch (recommended name: `cumulus-upgrade-VERSION`, where
   `VERSION` is the next version in the upgrade path).
1. Run `./set-cumulus-version VERSION` to update the version numbers of the
   Cumulus dependencies specified in various files.  This saves a bit of
   work hunting through the files to manually change version numbers.
1. Run `make all-init` to initialize the Terraform modules. (**NOTE:** This will
   take quite a bit of time, perhaps 45 minutes or more, because the Cumulus
   Terraform module file is rather large, and Terraform needlessly downloads the
   module file multiple times.)

Once Terraform is initialized, consult the release notes for the corresponding
Cumulus version, found on the [Cumulus releases] page. The release notes will
contain information about breaking changes, if any, and may also include
specific migration steps.

In some cases, an upgrade may consist of nothing more than the steps above. In
other cases, there may be Terraform configuration changes required, and possibly
even required code changes.

After consulting the release notes:

1. Make necessary code and configuration changes, if any.
1. Deploy the changes to a development stack (`make all-up-yes`). (**NOTE:**
   This may take quite a bit of time to complete, perhaps 30 minutes or more,
   depending on how many changes are required.)
1. Test the changes to make sure discovery and ingestion still work.
1. As needed, go back to step 1 until you confirm proper operation of Cumulus.
1. Commit and push all changes made to the branch and open a Pull Request (PR).
1. After your PR is approved, merge it into the `main` branch to have it
   automatically deployed to UAT.
1. Once deployment to UAT succeeds, run a sample discover/ingest to check that
   the upgrade works as expected. If not, make the necessary corrections.
1. Deploy to Production.

Go back to the top of this section, and repeat as necessary until you reach the
final Cumulus version in the upgrade path.

[Cumulus releases]: https://github.com/nasa/cumulus/releases
[Cumulus tags]: https://github.com/nasa/cumulus/tags
