name: BuildTrack CI

on:
push:
branches: [ "main", "develop" ]
pull_request:
branches: [ "main", "develop" ]

jobs:
build:
runs-on: ubuntu-latest

steps:
- name: Checkout code
uses: actions/checkout@v4

- name: Set up Flutter
uses: subosito/flutter-action@v2
with:
flutter-version: '3.24.0'

- name: Install dependencies
run: flutter pub get

- name: Analyze code
run: flutter analyze

- name: Run tests
run: flutter test
