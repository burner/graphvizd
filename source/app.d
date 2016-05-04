import std.stdio;

import graph;
import writer;

void main() {
	Graph g = new Graph();
	auto a = g.get!SubGraph("a");
	a.label =`<
		<table>
		<tr>
		<td> Module A</td>
		</tr>
		</table>
		>`;
	a.shape = "none";
	auto b = a.get!SubGraph("b");
	auto n = b.get!Node("node");
	n.label = `"Node"`;
	n.shape = "box";


	auto o = stderr.lockingTextWriter();
	auto w = new Writer!(typeof(o))(g, o, "Some\nMulti\n\tLine\n Description");
}
