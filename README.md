
# Emacs for Objective-C, Xcode

auto-complete + yasnippet

![auto-complete + yasnippet](https://raw2.github.com/ShingoFukuyama/images/master/emaXcode/emaXcode1.gif)

helm + yasnippet

![helm + yasnippet](https://raw2.github.com/ShingoFukuyama/images/master/emaXcode/emaXcode2.gif)

## Environment

I don't care other than this environment. Additionary, I change this package on a whim.

* Mac OSX 10.8.5 (MBPR2012)
* Xcode 5.1.1
* Emacs Cocoa 24.3.5 (from Homebrew)

## Requirement

As of May 26 2014, these are latest package

* auto-complete.el  1.4.0
* yasnippet.el  0.8.0
* helm.el  1.5.6

## Simple premise setting for each requirement

### auto-complete

```cl
(require 'auto-complete-config)
(ac-config-default)
(setq ac-use-menu-map t)
```

### yasnippet

```cl
(require 'yasnippet)
(setq yas-snippet-dirs "~/.emacs.d/lib/snippet") ;; for example
(yas-global-mode 1)
(setq yas-trigger-key (kbd "TAB"))
(yas--initialize)
```

### helm

```cl
(require 'helm-config)
(helm-mode 1)
```

### This package

```cl
(require 'emaXcode)
```

## Convert messages from Apple's header files to yasnippet

Extract about 2668 messages from header files directory, and convert them to a yasnippet file `.yas-compiled-snippets.el` with your existing snippets in objc-mode folder.

If header files directory path changed by Xcode's upgrade, set correct path to `emaXcode-yas-apple-headers-directory`. Currently "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.1.sdk/System/Library/Frameworks/Foundation.framework/Headers"

```cl
M-x emaXcode-yas-get-ios-messages-from-header-files
```

## Swith between header and implementation files

```cl
M-x emaXcode-open-corresponding-file
```

## Make new files subclassing from NSObject

```cl
M-x emaXcode-make-new-files-subclass-of-NSObject
```

## helm + yasnippet

* insert snippet: M-x yas-insert-snippet
* visit & edit snippet: M-x emaXcode-helm-yas-visit-snippet-file
* make new snippet from the region: M-x emaXcode-yas-new-snippet-from-region


## Reference

* http://sakito.jp/emacs/emacsobjectivec.html
