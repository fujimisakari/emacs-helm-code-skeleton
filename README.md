# helm-code-skeleton.el


## Introduction

`helm-code-skeleton.el' will be able to use code skeleton through helm interface


## Screenshot

![helm-code-skeleton](image/helm-code-skeleton.gif)


## Requirements

* Emacs 24.4 or higher
* helm 1.5 or higher


## Basic Usage

#### `helm-code-skeleton-search`

to search code skeleton


## Customize

#### `helm-code-skeleton-dir-path-alist`(Default: `'()`)

path of code-mode directory.

#### `helm-code-skeleton-exclude-load-regex`(Default: ".*\\(php-mode.el\\|php-mode-pkg.el\\|php-mode-autoloads.el\\)$")

Exclude load file name.

#### `helm-code-skeleton-maximum-candidates`(Default: `'200`)

Maximum number of helm candidates


## Sample Configuration

```lisp
(when (require 'helm-code-skeleton nil t)
  (require 'skeleton)
  (setq helm-code-skeleton-dir-path-alist '((php-mode . "$HOME/.emacs.d/elpa/php-mode-*")
                                            (lisp-interaction-mode . "$HOME/.emacs.d/code-skeleton/lisp")))
  (helm-code-skeleton-load))
```
