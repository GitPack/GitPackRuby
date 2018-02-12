## Conflict test case

Generate a known merge conflict. Several possibilities

* In all cases: modified fileB, unmanaged fileC
1. branchA modify fileA -- branchB modify fileB
2. branchA modify fileA -- branchB modify fileA
3. branchA unmanaged fileA -- branchB modify fileA
4. branchA remove fileA -- branchB modify fileA
5. branchA modify fileA -- branchB remove fileA

