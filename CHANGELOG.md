# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- New `Depot.Filesystem` callback `copy/4` to implement copy between filesystems

## [0.3.0] - 2020-07-29
### Added
- New `Depot.Filesystem` callback `read_stream/2`
- Added `:otp_app` key to `use Depot.Filesystem` macro to be able to store settings
in config files