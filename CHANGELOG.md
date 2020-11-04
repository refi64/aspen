# 0.4.0

- assets now contain their id
- the declaration of an asset changed (for all types of assets):
    - 0.3.0: `const myAsset = TextAsset(text: _myAsset$content);` 
    - 0.4.0: `const myAsset = TextAsset(_myAsset$asset);` 

# 0.3.0

- Revamp...everything.

# 0.2.2

- Stupid README fix.

# 0.2.1

- Fix a bug regarding codegen for named assets.

# 0.2.0

- Support inlining CSS URL dependencies.
- Support passing options to loaders.
- Support automatically loading assets.
- Many, many CLI improvements, including some nice progress.

# 0.1.3

- Fix a CSS loader bug.

# 0.1.1

- Fix a typo in the documentation.
- Add support for `-h` to show help.

# 0.1.0

Initial version.
