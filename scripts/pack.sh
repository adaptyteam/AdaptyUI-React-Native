rn_app_dir="../react-native-app/pure-0.71/node_modules/@adapty/react-native-ui"

yarn build
npm pack # yarn pack is extremely slow 

echo "Unzipping..."
tar -xf *.tgz
echo "Removing tarball..."
rm -rf *.tgz

echo "Removing previous lib..."
rm -rf $rn_app_dir # remove old version
echo "Moving to node_modules"
mv package $rn_app_dir
echo "Removing package folder..."
rm -rf package
  