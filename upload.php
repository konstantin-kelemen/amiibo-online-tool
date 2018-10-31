<?php
$target_dir = "uploads/";
$target_file = $target_dir . basename($_FILES["fileToUpload"]["name"]);
$target_key = $target_dir . basename($_FILES["keyToUpload"]["name"]);
$uploadOk = 1;
$dumpFileType = pathinfo($target_file,PATHINFO_EXTENSION);
$keyFileType = pathinfo($target_key,PATHINFO_EXTENSION);
$uid = str_replace('0x', '', $_POST["UID"]);
$uid = str_replace(' ', '', $uid);
$uid = escapeshellarg ( $uid );
// Check file size
if ($_FILES["fileToUpload"]["size"] > 600) {
    echo "Sorry, your dump is too large.<br>";
    $uploadOk = 0;
}
if ($_FILES["keyToUpload"]["size"] > 160 ) {
    echo "Sorry, your key is too large.<br>";
    $uploadOk = 0;
}

// Allow certain file formats
if($dumpFileType != "bin" ) {
    echo "Sorry, only bin files are allowed.<br>";
    $uploadOk = 0;
}
if($keyFileType != "bin" ) {
    echo "Sorry, only bin files are allowed.<br>";
    $uploadOk = 0;
}
// Check if $uploadOk is set to 0 by an error
if ($uploadOk == 0) {
    echo "Sorry, your dump was not uploaded.<br>";
// if everything is ok, try to upload file
} else {
    if (move_uploaded_file($_FILES["keyToUpload"]["tmp_name"], $target_key)) {
        $keyname = escapeshellarg ( basename( $_FILES["keyToUpload"]["name"]) );
    } else {
        echo "Sorry, there was an error uploading your key.<br>";
    }
    if (move_uploaded_file($_FILES["fileToUpload"]["tmp_name"], $target_file)) {
        $filename = escapeshellarg ( basename( $_FILES["fileToUpload"]["name"]) );
        $output = shell_exec( "./script.sh $keyname $filename $uid" );
        echo "<pre>".$output."</pre>";
    } else {
        echo "Sorry, there was an error uploading your dump.<br>";
    }
}
?>
