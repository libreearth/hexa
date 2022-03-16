locationHook = {
  mounted(){
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((position) => {
        this.pushEventTo("#image-form","location-avaliable", {lat: position.coords.latitude, lon: position.coords.longitude})
      });
    } 
  }
}

export default locationHook