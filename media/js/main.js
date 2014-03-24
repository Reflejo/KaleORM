var highlighter = new Sunlight.Highlighter();

// Async highlighting
marked.setOptions({
  highlight: function(code, lang, callback) {
    var nodes = highlighter.highlight(code, lang).getNodes();
    var div = document.createElement("div");
    for (var i = 0; i < nodes.length; i++) 
    {
      div.appendChild(nodes[i]);
    }
    callback(null, div.innerHTML);
  }
});

var $ = function(id) { return document.getElementById(id); };
function parse(data)
{
  var md = atob(data.data.content);
  marked(md, function(err, content){
    content = content.replace(/\[SQL:(.*)\]/g, "<a href='#' alt='$1' class='sql'>SQL</a>");
    $("docs").innerHTML = content;
    
    var tags = $("docs").getElementsByTagName("h2");
    for (var i = 0; i < tags.length; i++)
    {
      var li = document.createElement('li');
      var a = document.createElement('a');
      if (i == 0)
        li.className = "active";

      a.href = "#";
      a.innerHTML = tags[i].innerHTML;
      li.appendChild(a);
      $("options").appendChild(li);
    }
  });
}
//var script = document.createElement('script');
//script.src = 'https://api.github.com/repos/Reflejo/KaleORM/readme?callback=parse';
//document.getElementsByTagName('head')[0].appendChild(script);

var xhReq = new XMLHttpRequest();
xhReq.open("GET", "test", true);
xhReq.setRequestHeader("X-Requested-With", "XMLHttpRequest");
xhReq.send(null);
xhReq.onreadystatechange = function()
{
  if (xhReq.readyState == 4)
    parse({data: {content: btoa(xhReq.responseText)}});
};
