(function () {
  "use strict";

  function element(name, className, text) {
    var node = document.createElement(name);
    if (className) node.className = className;
    if (text) node.textContent = text;
    return node;
  }

  function link(href, text, className) {
    var node = element("a", className, text);
    node.href = href;
    return node;
  }

  function addReferenceIndexIntroduction() {
    var page = document.querySelector(".template-reference-index");
    var header = page && page.querySelector("main#main .page-header");
    if (!header || page.querySelector(".fs-reference-intro")) return;

    var intro = element("div", "fs-reference-intro");
    var copy = element(
      "p",
      null,
      "Functions are grouped by the work they help you do. Select a function for its usage, arguments, return value and runnable examples."
    );
    var catalogue = link(
      "../articles/options.html",
      "Compare all function arguments",
      "fs-reference-intro-link"
    );
    intro.appendChild(copy);
    intro.appendChild(catalogue);
    header.insertAdjacentElement("afterend", intro);
  }

  function topicPath(href) {
    return new URL(href, window.location.href).pathname;
  }

  function uniqueLinks(nodes) {
    var seen = new Set();
    return Array.prototype.filter.call(nodes, function (node) {
      var path = topicPath(node.getAttribute("href"));
      if (seen.has(path)) return false;
      seen.add(path);
      return true;
    });
  }

  function addCrumb(list, href, text, current) {
    var item = element("li", "fs-breadcrumb-item");
    if (current) {
      item.textContent = text;
      item.setAttribute("aria-current", "page");
    } else {
      item.appendChild(link(href, text));
    }
    list.appendChild(item);
    return item;
  }

  async function addReferenceTopicNavigation() {
    var page = document.querySelector(".template-reference-topic");
    var main = page && page.querySelector("main#main");
    var header = main && main.querySelector(".page-header");
    if (!header || main.querySelector(".fs-breadcrumb")) return;

    var sourceName = header.querySelector(".name code");
    var topic = sourceName
      ? sourceName.textContent.trim().replace(/\.Rd$/, "()")
      : header.querySelector("h1").textContent.trim();

    var breadcrumb = element("nav", "fs-breadcrumb");
    breadcrumb.setAttribute("aria-label", "Breadcrumb");
    var crumbs = element("ol", "fs-breadcrumb-list");
    addCrumb(crumbs, "../index.html", "Home", false);
    addCrumb(crumbs, "index.html", "Reference", false);
    var currentCrumb = addCrumb(crumbs, null, topic, true);
    breadcrumb.appendChild(crumbs);
    header.insertAdjacentElement("beforebegin", breadcrumb);

    var topicNav = element("nav", "fs-topic-nav");
    topicNav.setAttribute("aria-label", "Function reference navigation");
    var allFunctions = link("index.html", "All functions", "fs-topic-nav-all");
    topicNav.appendChild(allFunctions);
    main.appendChild(topicNav);

    try {
      var response = await fetch("index.html", { credentials: "same-origin" });
      if (!response.ok) return;
      var html = await response.text();
      var index = new DOMParser().parseFromString(html, "text/html");
      var links = Array.prototype.slice.call(
        index.querySelectorAll("main#main dl dt a[href]")
      );
      var currentPath = window.location.pathname;
      var currentLink = links.find(function (node) {
        return topicPath(node.getAttribute("href")) === currentPath;
      });
      if (!currentLink) return;

      topic = currentLink.textContent.trim();
      currentCrumb.textContent = topic;
      currentCrumb.setAttribute("aria-current", "page");

      var functionSection = currentLink.closest(".section.level2");
      var headingSection = functionSection;
      while (headingSection && !headingSection.querySelector("h2")) {
        headingSection = headingSection.previousElementSibling;
      }
      var groupHeading = headingSection && headingSection.querySelector("h2");
      if (groupHeading) {
        var groupItem = element("li", "fs-breadcrumb-item");
        groupItem.appendChild(
          link("index.html#" + groupHeading.id, groupHeading.textContent.trim())
        );
        crumbs.insertBefore(groupItem, currentCrumb);
        allFunctions.href = "index.html#" + groupHeading.id;
        allFunctions.textContent = "Back to " + groupHeading.textContent.trim();
      }

      var groupList = currentLink.closest("dl");
      var groupLinks = uniqueLinks(groupList.querySelectorAll("dt a[href]"));
      var currentIndex = groupLinks.findIndex(function (node) {
        return topicPath(node.getAttribute("href")) === currentPath;
      });

      if (currentIndex > 0) {
        var previous = groupLinks[currentIndex - 1];
        var previousLink = link(
          previous.getAttribute("href"),
          "Previous: " + previous.textContent.trim(),
          "fs-topic-nav-previous"
        );
        previousLink.rel = "prev";
        topicNav.insertBefore(previousLink, allFunctions);
      }
      if (currentIndex >= 0 && currentIndex < groupLinks.length - 1) {
        var next = groupLinks[currentIndex + 1];
        var nextLink = link(
          next.getAttribute("href"),
          "Next: " + next.textContent.trim(),
          "fs-topic-nav-next"
        );
        nextLink.rel = "next";
        topicNav.appendChild(nextLink);
      }
    } catch (error) {
      // The Home, Reference and All functions links remain usable when the
      // index cannot be read, for example when HTML is opened from disk.
    }
  }

  function initialise() {
    addReferenceIndexIntroduction();
    addReferenceTopicNavigation();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initialise);
  } else {
    initialise();
  }
})();
