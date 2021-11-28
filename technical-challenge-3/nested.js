const obj = {
   "data": [
      {
         "key": "x",
         "value": "a"
      },
      {
         "key": "y",
         "value": "a"
      },
      {
         "key": "z",
         "value": "a"
      }   

   ]
};
const findByKey = (obj, key) => {
   const arr = obj['data'];
   if(arr.length){
      const result = arr.filter(el => {
         return el['key'] === key;
      });
      if(result && result.length){
         return result[0].value;
      }
      else{
         return '';
      }
   }
}

console.log(findByKey(obj, 'x'));


console.log(findByKey(obj, 'y'));


console.log(findByKey(obj, 'z'));
