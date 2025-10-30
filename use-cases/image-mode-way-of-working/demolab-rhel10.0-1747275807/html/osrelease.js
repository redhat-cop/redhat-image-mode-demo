const btn = document.querySelector('button');
const main = document.querySelector('.container');
const url = 'os-release';
//console.log(btn);
btn.onclick = reqData;

// btn.onclick = () => {    console.log('Button clicked');}    

function output(data) {
    console.log(data);
    console.log(this);
    main.textContent = this.responseText;
}    

function reqData() {
    const xhr = new XMLHttpRequest();
    xhr.addEventListener('load',output);
    xhr.open('GET', url, true);
    xhr.send();
    console.log(xhr);
}
