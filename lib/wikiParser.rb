# coding: utf-8
require 'nokogiri'
require 'fileutils'
require(File.dirname(__FILE__)+'/wikiParserPage.rb')

# Parses a Wikipedia dump and extracts internal links, content, and page type.
class WikiParser

	# path to the Wikipedia dump.
	attr_reader :path

	# Convert the opened path to a dump to an enumerator of {WikiParser::Page}
	# @return [Enumerator<Nokogiri::XML::Node>] the enumerator.
	def parse
		@xml_file = File.open(@path)
		@file = Nokogiri::XML::Reader((@path.match(/.+\.bz2/) ? (require 'bzip2';Bzip2::Reader.open(@path)) : @xml_file), nil, 'utf-8', Nokogiri::XML::ParseOptions::NOERROR)
		@reader = @file.to_enum
	end

	# Convert the opened path to a dump to an enumerator of {WikiParser::Page}
	# @param opts [Hash] the parameters to parse a wikipedia page.
	# @option opts [String] :path The path to the Wikipedia dump in .xml or .bz2 format.
	# @return [Enumerator<Nokogiri::XML::Node>] the enumerator.
	def initialize (opts = {})
		@file, new_path = nil, opts[:path]
		if File.exists? new_path and !File.directory? new_path
			@path = new_path
			parse
		else
			raise ArgumentError.new "Cannot open file. Check path please."
		end
	end

	# Closes the file reader.
	def close; @xml_file.close if @xml_file; end

	# Skips a {WikiParser::Page} in the enumeration
	def skip
		begin
			node = @reader.next
			if node.name == "page" and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
			else
				skip
			end
		rescue StopIteration
			nil
		end
	end

	# Reads the next node in the xml tree and returns it as a {WikiParser#::Page} if it exists.
	# @return [WikiParser::Page, NilClass] A page if found.
	# @param opts [Hash] the parameters to instantiate a page.
	# @option opts [String] :until A node-name stopping point for the parsing. (Useful for not parsing an entire page until some property is checked.)
	# @see Page#finish_processing
	def get_next_page(opts={})
		begin
			node = @reader.next
			if node.name == "page" and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
				xml = Nokogiri::XML::parse("<page>"+node.inner_xml+"</page>").first_element_child
				return WikiParser::Page.new({:node => xml}.merge(opts))
			else
				get_next_page(opts)
			end
		rescue StopIteration, NoMethodError
			nil
		end
	end
end