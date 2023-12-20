window.addEventListener("load", ()=> {
    Array.from(document.querySelectorAll("div[stamp]")).map((ele)=> {
        ele.style.setProperty("--src", `url("${ele.getAttribute("src")}")`);
    })
})