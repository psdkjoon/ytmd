#!/usr/bin/env bash

! command -v ffmpeg >/dev/null 2>&1 && {
	echo "Installing ffmpeg..."
	sudo apt-get install -y ffmpeg 2>/dev/null ||
		sudo dnf install -y ffmpeg 2>/dev/null ||
		sudo pacman -S --noconfirm ffmpeg 2>/dev/null ||
		sudo zypper install -y ffmpeg 2>/dev/null ||
		sudo apk add ffmpeg 2>/dev/null ||
		{
			curl -L https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz | sudo tar -xJ -C /tmp &&
				sudo cp /tmp/ffmpeg-*-amd64-static/ffmpeg /usr/bin/ &&
				sudo chmod +x /usr/bin/ffmpeg &&
				rm -rf /tmp/ffmpeg-*-amd64-static
		}
}

! command -v yt-dlp >/dev/null 2>&1 && {
	echo "Installing yt-dlp..."
	sudo pip3 install yt-dlp 2>/dev/null ||
		sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/bin/yt-dlp && sudo chmod +x /usr/bin/yt-dlp
}

SUPPORTED="brave chrome chromium edge firefox opera safari vivaldi whale"

echo "Need a browser to get cookies from, Supported browsers are:"

echo "$SUPPORTED"
echo " "

read -r -p "Enter browser(leave empty for firefox): " BROWSER

if [[ -z "$BROWSER" ]]; then
	BROWSER="firefox"
	echo "Nothing entered, using firefox"
fi

if [[ ! " $SUPPORTED " =~ " $BROWSER " ]]; then
	echo "❌ Unsupported browser: $BROWSER"
	echo "Supported: $SUPPORTED"
	exit 1
fi

sudo tee /usr/bin/ytmd >/dev/null <<EOF
#!/usr/bin/env bash
[[ -f "$1" ]] && while read -r url; do yt-dlp -f "bestaudio" -x --audio-format mp3 --audio-quality 0 --cookies-from-browser $BROWSER --write-thumbnail --convert-thumbnails png --output "%(album)s//*\\%(artist)s//*\\%(title)s.%(ext)s" "$url"; done <"$1" || yt-dlp -f "bestaudio" -x --audio-format mp3 --audio-quality 0 --cookies-from-browser $BROWSER --write-thumbnail --convert-thumbnails png --output "%(album)s//*\\%(artist)s//*\\%(title)s.%(ext)s" "$1"
for f in *.mp3; do
	[[ ! -f "$f" ]] && continue
	base="${f%.mp3}"
	IFS='//*\\' read -r album artist title <<<"$base"
	cover="$base.png"
	sq="$base.sq.png"
	w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$cover")
	h=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$cover")
	s=$((w < h ? w : h))
	x=$(((w - s) / 2))
	y=$(((h - s) / 2))
	ffmpeg -i "$cover" -vf "crop=$s:$s:$x:$y" -vframes 1 "$sq" -y -loglevel error 2>/dev/null
	mkdir -p "${artist%%, *}"
	ffmpeg -i "$f" -i "$sq" -map 0:a -map 1 -c copy \
		-metadata title="$title" -metadata artist="$artist" -metadata album="$album" \
		-disposition:v attached_pic "$artist/$f" -y -loglevel error
	echo "✅ $f → $artist/"
done
rm -f *.png *.jpg *.mp3
EOF

sudo chmod +x /usr/bin/ytmd
sudo rm -rf README.de.md README.es.md README.fa.md README.fr.md README.jp.md README.md README.ru.md README.zh.md
