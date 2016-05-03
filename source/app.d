import std.stdio;

import graph;
import writer;

void main() {
	Graph g = new Graph();

	auto o = stderr.lockingTextWriter();
	auto w = new Writer!(typeof(o))(g, o, "Some\nMulti\n\tLine\n Description");
}
