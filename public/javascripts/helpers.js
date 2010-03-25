


function format_number(num){
  var n = num;
  var decimals = arguments[1];
  
  if( decimals == null ){ decimals = 2; }
  
  if( decimals == 0 ){
    n= Math.floor(num);
  }
  else {
    n = parseFloat( num.toFixed(decimals) );
  }
  
  return n.toString();
}

function find_nearest_speed(v){
  var result = _format_speed(v);
  var nearest = Math.round(result[0]);
  return nearest * Math.pow(1024, result[1]);
}

function _format_speed(speed){
  speed= parseInt(speed);
  if ( speed == 0 ){ return [0, 0]; }
  else if( speed < Math.pow(1024, 1) ){ return [speed + 0.0, 0]; }
  else if( speed < Math.pow(1024, 2) ){ return [speed/Math.pow(1024, 1), 1]; }
  else if( speed < Math.pow(1024, 3) ){ return [speed/Math.pow(1024, 2), 2]; }
  else if( speed < Math.pow(1024, 4) ){ return [speed/Math.pow(1024, 3), 3]; }
  else{
    return [speed/Math.pow(1024, 4), 4];
  }
}

function format_speed(speed){
  var result = _format_speed(speed);
  
  if( result[0] == 0 ){
    return format_number(result[0], 0);
  }
  
  switch( result[1] ){
    case 0 : return format_number(result[0], 0) + " o/s"; break;
    case 1 : return format_number(result[0], 1) + " Ko/s"; break;
    case 2 : return format_number(result[0], 2) + " Mo/s"; break;
    case 3 : return format_number(result[0], 2) + " Go/s"; break;
    default : return format_number(result[0], 2) + " To/s"; break;
  }
  
  // speed= parseInt(speed);
  // if ( speed == 0 ){ return '0'; }
  // else if( speed < Math.pow(1024, 1) ){    return format_number(speed + 0.0, 0) + " o/s"; }
  // else if( speed < Math.pow(1024, 2) ){ return format_number(speed/Math.pow(1024, 1), 2) + " Ko/s"; }
  // else if( speed < Math.pow(1024, 3) ){   return format_number(speed/Math.pow(1024, 2), 2) + " Mo/s"; }
  // else if( speed < Math.pow(1024, 4) ){ return format_number(speed/Math.pow(1024, 3), 2) + " Go/s"; }
  // else{
  //   return speed.toString();
  // }
}



// find the nearest size nicely displayable
// prefer 12Go to 12.234Go
function find_nearest_size(v){
  // first find the value which would be displayed with this value
  var result = _format_size(v);
  
  // round this value
  var nearest = Math.round(result[0]);
  
  return nearest * Math.pow(1024, result[1]);
}

// return size as it would be shown and unit as integer (indice)
function _format_size(size){
  size = parseInt(size);
  if( size == 0 ){ return '0'; }
  else if( size < Math.pow(1024, 1) ){     return [size, 0]; }
  else if( size < Math.pow(1024, 2) ){  return [size/Math.pow(1024, 1), 1]; }
  else if( size < Math.pow(1024, 3) ){  return [size/Math.pow(1024, 2), 2]; }
  else if( size < Math.pow(1024, 4) ){  return [size/Math.pow(1024, 3), 3]; }
  else if( size < Math.pow(1024, 5) ){  return [size/Math.pow(1024, 4), 4]; }
  else{
    return [size/Math.pow(1024, 5), 5];
  }
}

function format_size(size){
  var result = _format_size(size);
  
  switch( result[1] ){
    case 0 : return format_number(result[0], 0) + " Octets"; break;
    case 1 : return format_number(result[0], 1) + " Ko"; break;
    case 2 : return format_number(result[0], 2) + " Mo"; break;
    case 3 : return format_number(result[0], 2) + " Go"; break;
    case 4 : return format_number(result[0], 2) + " To"; break;
  }
  
  // size= parseInt(size);
  // if( size == 0 ){ return '0'; }
  // else if( size < Math.pow(1024, 1) ){     return format_number(size, 0) + " Octets"; }
  // else if( size < Math.pow(1024, 2) ){  return format_number(size/Math.pow(1024, 1), 0) + " Ko"; }
  // else if( size < Math.pow(1024, 3) ){  return format_number(size/Math.pow(1024, 2), 1) + " Mo"; }
  // else if( size < Math.pow(1024, 4) ){  return format_number(size/Math.pow(1024, 3), 2) + " Go"; }
  // else if( size < Math.pow(1024, 5) ){  return format_number(size/Math.pow(1024, 4), 2) + " To"; }
  // else{
  //   return size;
  // }
}


function format_ping(t){
  return format_number(t, 2) + "ms"
}





function format_duration(t){
  t= parseInt(t);
  days= hours= minutes= seconds= 0;
  
  while(t > 0){
    if( t > 24*60*60 ){   days++; t-= 24*60*60; }
    else if( t > 1*60*60 ){ hours++; t-= 1*60*60; }
    else if( t > 1*60 ){  minutes++; t-= 1*60; }
    else{
      seconds+= 1; t--;
    }
  }
  
  while(true){
    if( seconds >= 60 ){    seconds-= 60; minutes++; }
    else if( minutes >= 60 ){ minutes-= 60; hours++; }
    else if( hours >= 24 ){   hours-= 24; days++; }
    else{
      break;
    }
  }
  
  ret= ""
  if(days > 0){ ret+= pluralize(days, "jour", "jours"); }
  if(hours > 0){ ret+= " " + pluralize(hours, "heure", "heures"); }
  if(minutes > 0){ ret+= " " + pluralize(minutes, "min", "mins"); }
  if(seconds > 0){ ret+= " " + pluralize(seconds, "s", "s"); }
  
  return ret;
}

