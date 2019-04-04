# 0. Copy env_.sh to env.sh and fill in as needed! Generate the templates as described in env.sh

# 1. Extra the frames (note the %05d)
$FFMPEG -i "$in_file" -f image2 "${frames_dir}/%05d.png"
# 2. Manually clean-up the frames: remove the finale before the min and after the max frame.
# 3. Read the QR code in each frame and save the results in qr.csv
./extract-qr.sh "$frames_dir" > "${out_dir}/qr.csv"

# 4. Run the PSNR algorithm (use out of range values for min and max to disable: 0 and 111111).
$PYTHON psnr.py "${out_dir}/qr.csv" "$frames_dir" 0 111111 > "${out_dir}/psnr.txt"

