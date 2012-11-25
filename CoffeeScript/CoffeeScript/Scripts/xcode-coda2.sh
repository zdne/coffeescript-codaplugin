# Clean up any previous products/symbolic links in the plug-ins folder
echo "${USER_LIBRARY_DIR}/Application Support/Coda 2/Plug-ins/${FULL_PRODUCT_NAME}"

if [ -a "${USER_LIBRARY_DIR}/Application Support/Coda 2/Plug-ins/${FULL_PRODUCT_NAME}" ]; then
    rm -Rf "${USER_LIBRARY_DIR}/Application Support/Coda 2/Plug-ins/${FULL_PRODUCT_NAME}"
fi

# Depending on the build configuration, either copy or link to the most recent product
if [ "${CONFIGURATION}" == "Debug" ]; then
    # If we're debugging, add a symbolic link to the plug-in
    ln -sf "${TARGET_BUILD_DIR}/${FULL_PRODUCT_NAME}" \
        "${USER_LIBRARY_DIR}/Application Support/Coda 2/Plug-ins/${FULL_PRODUCT_NAME}"
elif [ "${CONFIGURATION}" == "Release" ]; then
    # If we're compiling for release, just copy the plugin to the Coda 2 Plug-ins folder
    cp -Rfv "${TARGET_BUILD_DIR}/${FULL_PRODUCT_NAME}" \
        "${USER_LIBRARY_DIR}/Application Support/Coda 2/Plug-ins/${FULL_PRODUCT_NAME}"
fi