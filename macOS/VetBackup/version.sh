#!/bin/sh

#  version.sh
#  VetBackup
#
#  Created by Anton Dahlén on 2026-08-21.
#

# https://medium.com/@mateuszsiatrak/automating-build-number-increments-in-xcode-with-custom-format-a-practical-guide-bcc90a19f716

cd "${SRCROOT}/${PRODUCT_NAME}"

#
# date based build number:
#
#current_date=$(date "+%Y%m%d")
#previous_build_number=$(awk -F "=" '/BUILD_NUMBER / {print $2}' version.xcconfig | tr -d ' ')
#previous_date="${previous_build_number:0:8}"
#counter="${previous_build_number:8}"
#new_counter=$((current_date == previous_date ? counter + 1 : 1))
#new_build_number="${current_date}${new_counter}"
#sed -i -e "/BUILD_NUMBER =/ s/= .*/= $new_build_number/" version.xcconfig
#rm -f version.xcconfig-e
# this file ^ is a temp file created by sed, delete it

#
# date based, trailing hex:
#
#current_date=$(date "+%Y%m%d")
#previous_build_number=$(awk -F "=" '/BUILD_NUMBER / {print $2}' version.xcconfig | tr -d ' ')
#previous_date="${previous_build_number:0:8}"
#counter="${previous_build_number:8}"
#new_counter=$((current_date == previous_date ? counter + 1 : 1))
#new_counter_hex=$(bc <<< "obase=16; $new_counter")
#new_build_number="${current_date}${new_counter}"
#new_build_number_hex="${current_date}${new_counter_hex}"
#sed -i -e "/BUILD_NUMBER =/ s/= .*/= $new_build_number/" version.xcconfig
#rm -f version.xcconfig-e
#sed -i -e "/BUILD_NUMBER_HEX =/ s/= .*/= $new_build_number_hex/" version.xcconfig
#rm -f version.xcconfig-e

#
# simple incrementing int
#
previous_build_number=$(awk -F "=" '/BUILD_NUMBER / {print $2}' version.xcconfig | tr -d ' ')
new_build_number=$((previous_build_number + 1))
new_build_number_hex=$(bc <<< "obase=16; $new_build_number")
sed -i -e "/BUILD_NUMBER =/ s/= .*/= $new_build_number/" version.xcconfig
rm -f version.xcconfig-e
sed -i -e "/BUILD_NUMBER_HEX =/ s/= .*/= $new_build_number_hex/" version.xcconfig
rm -f version.xcconfig-e
