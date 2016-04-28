module graph;

import std.typecons : Rebindable, RefCounted;
import containers.hashmap;
import containers.dynamicarray;
import containers.cyclicbuffer;

immutable DummyString = "__dummy";

class Graph {
	HashMap!(string,Node) nodes;
	HashMap!(string,Edge) edges;
	bool firstEdgeCreated = false;

	string deapest(string path) const {
		import std.array : appender;
		import std.stdio : writeln;
		CyclicBuffer!string split;
		splitString(split, path);

		if(split.empty || !(split.front in this.nodes)) {
			return "";
		}

		Rebindable!(const Node) next = this.nodes[split.front];
		auto app = appender!string();
		app.put(split.front);
		split.removeFront();

		while(!split.empty && next !is null) {
			SubGraph sg = cast(SubGraph)next;
			if(sg is null) {
				break;
			} else {
				if(split.front in sg.nodes) {
					next = sg.nodes[split.front];
					app.put(split.front);
					split.removeFront();
				} else {
					break;
				}
			}
		}

		SubGraph lastSG = cast(SubGraph)next;
		if(!split.empty || lastSG !is null) {
			app.put(DummyString);
		}

		return app.data;
	}


	T get(T)(in string name, in string from, in string to) if(is(T == Edge)) {
		firstEdgeCreated = true;
		if(name in this.edges) {
			return cast(T)this.edges[name];
		} else {
			T ret = new T(name, this.deapest(from), this.deapest(to));
			this.edges[name] = ret;
			return ret;
		}
	}
			
	T get(T)(in string name) if(!is(T == Edge)) {
		if(name in this.nodes) {
			return cast(T)this.nodes[name];
		} else {
			if(firstEdgeCreated) {
				throw new Exception("Node's can't be created after the "
					~ "first Edge has been created"
				);
			}
			T ret = new T(name, null);
			this.nodes[name] = ret;
			return ret;
		}
		
	}
}

class Node {
	const(string) name;
	Node parent;
	string label;
	this(in string name, Node parent) {
		this.name = name;
		this.parent = parent;
	}
}

class DummyNode : Node {
	this(Node parent) {
		super(DummyString, parent);
	}
}

class SubGraph : Node {
	HashMap!(string,Node) nodes;

	this(in string name, Node parent) {
		super(name, parent);
		this.nodes[DummyString] =  new Node(DummyString, this);
	}

	T get(T)(in string name) {
		if(name in this.nodes) {
			return cast(T)this.nodes[name];
		} else {
			T ret = new T(name, this);
			this.nodes[name] = ret;
			return ret;
		}
	}
}

class Edge {
	const(string) name;
	DynamicArray!string from;
	DynamicArray!string to;
	string label;
	string arrowStyleFrom;
	string arrowStyleTo;
	string edgeStyle;

	this(in string name, in string from, in string to) {
		this.name = name;
	}

}

private void splitString(O)(ref O or, in string str) {
	import std.algorithm.iteration : splitter;
	foreach(it; str.splitter(".")) {
		or.insert(it);
	}
}

unittest {
	import std.exception : assertThrown;
	auto g = new Graph();
	auto n = g.get!Node("a");
	auto m = g.get!Node("b");
	auto e = g.get!Edge("e", "a", "b");
	assertThrown(g.get!Node("c"));
}

unittest {
	auto g = new Graph();
	auto a = g.get!SubGraph("a");
	assert(g.deapest("a") == "a__dummy");
	auto b = a.get!Node("b");
	assert(g.deapest("a.b") == "ab");
	assert(g.deapest("c") == "");
	auto c = a.get!SubGraph("c");
	assert(g.deapest("a.c") == "ac__dummy");
	assert(g.deapest("a.c.e") == "ac__dummy");
	assert(g.deapest("a.d.e") == "a__dummy");
	auto d = c.get!Node("d");
	assert(g.deapest("a.c.d") == "acd");
}

unittest {
	auto g = RCString!Graph();
}
