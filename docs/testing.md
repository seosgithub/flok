# Testing
Testing is broken down into 2 parts.

1. Tests that are run on the **pure JS kernel**
2. Tests that are run with a **platform**

For tests that are run on the **pure JS kernel**, these import `application.js` and use RSpec along with execJS to verify behavior. Sometimes, when
testing code merging, the literal text files are compared. You can test `application.js` by running `rake spec:kernel`. All spec files for anything
not platform dependent go into `./spec/`.  For all **platform** dependent spec files, they go into `./spec/platform`.
