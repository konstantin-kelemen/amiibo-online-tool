#!/bin/bash
# This is a companion script to https://github.com/konstantin-kelemen/arduino-amiibo-tools 
# For more info go to https://games.kel.mn/en/create-amiibo-clones-with-arduino/

#requirements:
#sha1sum (part of coreutils)
#xxd (part of vim)
#hexdump 
#amiitool (https://github.com/socram8888/amiitool)

key="uploads/$1"
dump="uploads/$2"

if [ "$(sha1sum $key | cut -d " " -f1)" != "bbdbb49a917d14f7a997d327ba40d40c39e606ce" ]
then
	echo "Key is incorrect"
	rm "$key" "$dump"
	exit
fi

#get the empty tag uid:
taguid=$3

taguid0="$(echo "$taguid" | cut -b1,2)"		# Byte 0 (should be 0x04) 
taguid1="$(echo "$taguid" | cut -b3,4)"   	# Byte 1 (we count from 0)
taguid2="$(echo "$taguid" | cut -b5,6)"   	# Byte 2

if [ ${#3} -eq 18 ]; then # Check if user provided a long taguid
	
	taguid3="$(echo "$taguid" | cut -b9,10)"  # Byte 4
	taguid4="$(echo "$taguid" | cut -b11,12)" # Byte 5
	taguid5="$(echo "$taguid" | cut -b13,14)" # Byte 6
	taguid6="$(echo "$taguid" | cut -b15,16)" # Byte 7

	uid="$(echo "$taguid" | cut -b1-16)"
	BCC1="$(echo "$taguid" | cut -b17,18)"	# Pull out the BCC1 for use later

	elif [ ${#3} -eq 14 ]; then # Check if user provided a short taguid

		taguid3="$(echo "$taguid" | cut -b7,8)"   # Byte 3
		taguid4="$(echo "$taguid" | cut -b9,10)"  # Byte 4
		taguid5="$(echo "$taguid" | cut -b11,12)" # Byte 5
		taguid6="$(echo "$taguid" | cut -b13,14)" # Byte 6

		# Convert 7byte to 9byte for script
		BCC0="$(printf '%02X\n' $(( 0x88 ^ 0x$taguid0 ^ 0x$taguid1 ^ 0x$taguid2 )))"  		# Calculate the BCC0
		BCC1="$(printf '%02X\n' $(( 0x$taguid3 ^ 0x$taguid4 ^ 0x$taguid5 ^ 0x$taguid6 )))" 	# Calculate the BCC1
		uid="$taguid0$taguid1$taguid2$BCC0$taguid3$taguid4$taguid5$taguid6"
fi

if [ ${#uid} -ne 16 ]; then 
	echo "Please specify a valid 7 or 9 byte UID"
	rm "$key" "$dump"
	exit
fi

# Generate the password from the tag

pw1="$(printf '%02X\n' $(( 0xAA ^ 0x$taguid1 ^ 0x$taguid3 )))"
pw2="$(printf '%02X\n' $(( 0x55 ^ 0x$taguid2 ^ 0x$taguid4 )))"
pw3="$(printf '%02X\n' $(( 0xAA ^ 0x$taguid3 ^ 0x$taguid5 )))"
pw4="$(printf '%02X\n' $(( 0x55 ^ 0x$taguid4 ^ 0x$taguid6 )))"

#decrypt the dump
./amiitool -d -k "$key" -i "$dump" -o dec.bin

#modify the uid record
echo "01D4: $uid" | xxd -r - dec.bin

#add password 
echo "0214: $pw1$pw2$pw3$pw4" | xxd -r - dec.bin #pw
echo "0218: 8080" | xxd -r - dec.bin 

#set the default values 
echo "0208: 000000" | xxd -r - dec.bin
echo "0000: $BCC1" | xxd -r - dec.bin
echo "0002: 0000" | xxd -r - dec.bin

#reencrypt the uid modified dump
./amiitool -e -k "$key" -i dec.bin -o enc.bin

#hexdump -v -e " 4/1 \"0x%02X, \" \"\n\"" "enc.bin" > hexdump
xxd -i -c 4 enc.bin | tail -n +2 | head -n 135 | sed "s/  //g"
#truncate -s-2 hexdump
#echo "" >> hexdump
#echo "" >> hexdump
#cat hexdump
rm dec.bin enc.bin "$key" "$dump"
