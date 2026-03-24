#!/bin/bash
# Rebuild bat's theme cache so custom .tmTheme files are recognized.
if command -v bat >/dev/null 2>&1; then
  bat cache --build
fi
