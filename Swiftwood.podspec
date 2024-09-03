#
# Be sure to run `pod lib lint StackKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
	s.name             = 'Swiftwood'
	s.version          = '0.4.7'
	s.summary          = 'A logging package for swift projects'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!

	s.description      = """
	A logging package for swift projects. ('swiftwood' is a pun of 'driftwood' since logs are often just tossed into the stream of events to be lost amidst the wilderness)
	"""

	s.homepage         = 'https://github.com/mredig/Swiftwood'
	s.license          = { :type => 'MIT', :file => 'LICENSE' }
	s.author           = { 'mredig' => 'xxx@xxx.xx' }
	s.source           = { :git => 'https://github.com/mredig/Swiftwood', :tag => s.version.to_s }

	s.ios.deployment_target = '9.0'

	s.source_files = 'Sources/Swiftwood/**/*'

	s.test_spec 'Tests' do |test_spec|
		test_spec.source_files = 'Tests/SwiftwoodTests/**/*'
	end

end
