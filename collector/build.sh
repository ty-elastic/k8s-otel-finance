arch=linux/amd64
course=latest
repo=us-central1-docker.pkg.dev/elastic-sa/tbekiares
while getopts "a:c:r:" opt
do
   case "$opt" in
      a ) arch="$OPTARG" ;;
      c ) course="$OPTARG" ;;
      r ) repo="$OPTARG" ;;
   esac
done

collector_distribution_image_name=$repo/otelcol

docker build \
  -t $collector_distribution_image_name:$course \
  --platform=$arch .

docker push $collector_distribution_image_name:$course
