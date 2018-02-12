## Conflict test case

Testing for the solution proposed here - https://stackoverflow.com/questions/6335717/can-git-tell-me-if-a-merge-will-conflict-without-actually-merging

In particular
```
git format-patch $(git merge-base branch1 branch2)..branch2 --stdout | git apply --check -

```

Generate a known merge conflict. Several possibilities:

* In all cases: modified fileB, unmanaged fileC
1. branchA modify fileA -- branchB modify fileB
2. branchA modify fileA -- branchB modify fileA
3. branchA unmanaged fileA -- branchB modify fileA
4. branchA remove fileA -- branchB modify fileA
5. branchA modify fileA -- branchB remove fileA

